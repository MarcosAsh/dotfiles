#!/usr/bin/env bash
# Symlink the configs in this repo into ~/.config, and the scripts into ~/.local/bin.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"

mkdir -p "$CONFIG" "$BIN"

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

link_bin display-auto
link_bin display-watch

echo
echo "Done. Neovim will install its plugins on first launch."
