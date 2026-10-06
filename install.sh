#!/usr/bin/env bash
# Symlink the configs in this repo into ~/.config and ~, and the scripts into ~/.local/bin.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"

mkdir -p "$CONFIG" "$BIN" "$CONFIG/restic" "$CONFIG/systemd/user"

backup() {
    local dst="$1"

    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        mv "$dst" "$dst.bak.$(date +%s)"
        echo "backed up existing $dst"
    fi
}

link() {
    local src="$DOTFILES/$1"
    local dst="$CONFIG/$1"

    backup "$dst"
    ln -s "$src" "$dst"
    echo "linked $dst -> $src"
}

link_home() {
    local src="$DOTFILES/$1"
    local dst="$HOME/$2"

    backup "$dst"
    ln -s "$src" "$dst"
    echo "linked $dst -> $src"
}

link_bin() {
    local src="$DOTFILES/bin/$1"
    local dst="$BIN/$1"

    backup "$dst"
    ln -s "$src" "$dst"
    echo "linked $dst -> $src"
}

link nvim
link i3
link i3status
link kitty
link restic/excludes
link systemd/user/restic-backup.service
link systemd/user/restic-backup.timer
link systemd/user/restic-prune.service
link systemd/user/restic-prune.timer

link_home bash/bashrc .bashrc
link_home git/gitconfig .gitconfig

link_bin display-auto
link_bin display-watch
link_bin power-auto
link_bin backup

echo
echo "Done. Neovim will install its plugins on first launch."
