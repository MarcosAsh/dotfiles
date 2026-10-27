#!/usr/bin/env bash
# Rebuild the Ventoy stick with 50 GiB reserved, restore its contents, then
# install NixOS (flake in this directory) into the reserved space.
#
# Run as root from a normal session on the laptop, with Nix installed:
#   sudo ~/dotfiles/nixos/install-usb.sh
#
# Needs: the backup in ~/ventoy-backup, the Ventoy tarball unpacked in
# ~/nixusb-work/ventoy-dl, and network for the nixpkgs download.
set -euo pipefail

DEV=/dev/sda
WANT_MODEL="3.2Gen1"
RESERVE_MIB=51200
USER_NAME=marcosash
NIX_USER_HOME=$(getent passwd "${SUDO_USER:?run with sudo}" | cut -d: -f6)
BACKUP="$NIX_USER_HOME/ventoy-backup"
VENTOY="$NIX_USER_HOME/nixusb-work/ventoy-dl/ventoy-1.1.18"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(dirname "$SRC")"
export PATH=/nix/var/nix/profiles/default/bin:$PATH

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
command -v nix >/dev/null || { echo "nix not found, install it first" >&2; exit 1; }

# --- Make sure DEV is the stick and nothing else ---
[ "$(lsblk -dno TRAN "$DEV")" = usb ] || { echo "$DEV is not a USB disk" >&2; exit 1; }
lsblk -dno MODEL "$DEV" | grep -q "$WANT_MODEL" || { echo "$DEV is not the SanDisk $WANT_MODEL" >&2; exit 1; }
[ "$(lsblk -dbno SIZE "$DEV")" -gt $((100 * 1024**3)) ] || { echo "$DEV is smaller than expected" >&2; exit 1; }
if findmnt -n -o SOURCE / | grep -q "^$DEV"; then echo "$DEV holds the running system" >&2; exit 1; fi

if [ "${1:-}" != --install-only ]; then
# --- Make sure the backup matches what is on the stick ---
[ -d "$BACKUP/isos" ] || { echo "backup missing at $BACKUP" >&2; exit 1; }
CHECK=$(mktemp -d)
mount -o ro "${DEV}1" "$CHECK"
DIFF=$(rsync -rn --size-only --itemize-changes "$CHECK"/ "$BACKUP"/ | grep -v '^\.d' || true)
umount "$CHECK"; rmdir "$CHECK"
if [ -n "$DIFF" ]; then echo "backup differs from the stick:"; echo "$DIFF" | head; exit 1; fi
echo "Backup matches the stick."

lsblk -o NAME,SIZE,MODEL,FSTYPE,LABEL "$DEV"
read -rp "Type 'wipe sda' to repartition $DEV (Ventoy is reinstalled, data restored from backup): " ans
[ "$ans" = "wipe sda" ] || { echo aborted; exit 1; }

# --- 1. Ventoy with space reserved at the end ---
for p in "$DEV"?*; do umount "$p" 2>/dev/null || true; done
(cd "$VENTOY" && printf 'y\ny\n' | ./Ventoy2Disk.sh -I -r "$RESERVE_MIB" "$DEV")
udevadm settle; partprobe "$DEV"; sleep 2

# --- 2. Restore the Ventoy data and add the NixOS menu entry ---
DATA=$(mktemp -d)
mount "${DEV}1" "$DATA"
rsync -rt --info=progress2 "$BACKUP"/ "$DATA"/
cat > "$DATA/ventoy/ventoy_grub.cfg" <<'EOF'
menuentry "NixOS (installed on this stick)" --class=nixos {
    search --no-floppy --label NIXOS-BOOT --set=nixboot
    chainloader ($nixboot)/EFI/BOOT/BOOTX64.EFI
}
EOF
sync; umount "$DATA"; rmdir "$DATA"

# --- 3. NixOS partitions in the reserved space ---
echo 'size=1GiB, type=U' | sfdisk --append "$DEV"
echo 'type=L' | sfdisk --append "$DEV"
udevadm settle; partprobe "$DEV"; sleep 2
mkfs.vfat -F32 -n NIXOS-BOOT "${DEV}3"
mkfs.ext4 -F -L NIXOS-ROOT "${DEV}4"

else
# Resume after a failed install: partitions and Ventoy data are already in place
[ "$(blkid -s LABEL -o value "${DEV}3")" = NIXOS-BOOT ] && [ "$(blkid -s LABEL -o value "${DEV}4")" = NIXOS-ROOT ] \
    || { echo "NixOS partitions not found on $DEV, run without --install-only" >&2; exit 1; }
fi

MNT=/mnt/nixusb
mkdir -p "$MNT"
mount "${DEV}4" "$MNT"
mkdir -p "$MNT/boot"
mount "${DEV}3" "$MNT/boot"
trap 'umount -R "$MNT" 2>/dev/null || true' EXIT

# --- 4. Install ---
mkdir -p "$MNT/etc/nixos"
cp "$SRC"/flake.nix "$SRC"/flake.lock "$SRC"/hardware.nix "$SRC"/configuration.nix "$MNT/etc/nixos/"

TOOLS=$(nix --extra-experimental-features 'nix-command flakes' build --no-link --print-out-paths nixpkgs#nixos-install-tools)
export PATH="$TOOLS/bin:$PATH"
nixos-install --root "$MNT" --flake "$MNT/etc/nixos#nixusb" --no-root-passwd

# --- 5. Home directory: dotfiles, wallpapers, then the repo's own installer ---
HOME_DIR="$MNT/home/$USER_NAME"
mkdir -p "$HOME_DIR/Pictures"
cp -a "$DOTFILES" "$HOME_DIR/dotfiles"
cp -a "$NIX_USER_HOME/Pictures/wallpapers" "$HOME_DIR/Pictures/wallpapers"
chown -R 1000:100 "$HOME_DIR"
nixos-enter --root "$MNT" -c "su - $USER_NAME -c '~/dotfiles/install.sh'"

echo "Set the password for $USER_NAME:"
nixos-enter --root "$MNT" -c "passwd $USER_NAME"

sync
umount -R "$MNT"
trap - EXIT
echo "Done. Boot the stick and pick 'NixOS (installed on this stick)' in the Ventoy menu."
