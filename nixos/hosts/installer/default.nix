# Installer USB: boots, gets DHCP and lets the laptop in over SSH as root, so
# nixos-anywhere can do the rest. Build with
#   nix build .#nixosConfigurations.installer.config.system.build.isoImage
{ modulesPath, lib, ... }:

{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  networking.hostName = "nixos-installer";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGraBN/jn+4lOb7Ma0Wraw8hU1BtYM9o6iiQf8zTdzVF claude-code-keras"
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
}
