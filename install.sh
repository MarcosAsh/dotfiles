#!/usr/bin/env bash
# Symlink the configs in this repo into ~/.config.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

mkdir -p "$CONFIG"

link() {
    local src="$DOTFILES/$1"
    local dst="$CONFIG/$1"

    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        mv "$dst" "$dst.bak.$(date +%s)"
        echo "backed up existing $dst"
    fi

    ln -s "$src" "$dst"
    echo "linked $dst -> $src"
}

link nvim
link i3
link i3status
link kitty

echo
echo "Done. Neovim will install its plugins on first launch."
