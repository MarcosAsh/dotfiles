#!/usr/bin/env bash
# One-shot setup for the Ubuntu live session on the Ventoy stick.
# Persistence keeps everything, so this only needs running once.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo apt-get update
# i3 and everything its config starts, then the nvim toolchain. python3-venv
# lets mason build its Python-based tools, bear writes compile_commands.json
# for clangd, zathura is the vimtex PDF viewer.
sudo apt-get install -y \
    i3 xorg brightnessctl feh dunst i3lock xss-lock blueman \
    ripgrep fd-find build-essential git curl unzip python3-venv \
    clang-format bear zathura latexmk

mkdir -p ~/.local/bin ~/.local/share

# Ubuntu's neovim is 0.9, the config needs 0.12
if [ ! -x ~/.local/share/nvim-linux-x86_64/bin/nvim ]; then
    curl -fL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
        | tar xz -C ~/.local/share
fi
ln -sfn ~/.local/share/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim

# nvim-treesitter's main branch compiles parsers with the tree-sitter CLI
if [ ! -x ~/.local/bin/tree-sitter ]; then
    curl -fL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
        | gunzip > ~/.local/bin/tree-sitter
    chmod +x ~/.local/bin/tree-sitter
fi

if [ ! -x ~/.local/kitty.app/bin/kitty ]; then
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
fi
ln -sfn ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty

if ! fc-list | grep -q JetBrainsMono; then
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip && rm JetBrainsMono.zip
    fc-cache -f
    cd -
fi

# The stick carries the wallpaper the i3 config points at
if [ -d "$SRC/../wallpapers" ]; then
    mkdir -p ~/Pictures/wallpapers
    cp -n "$SRC"/../wallpapers/* ~/Pictures/wallpapers/
fi

command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

# Copy off the stick so the symlinks don't depend on it being mounted
[ -d ~/dotfiles ] || cp -a "$SRC" ~/dotfiles
~/dotfiles/install.sh

# Install plugins, parsers and mason tools now rather than on first open.
# The second run loads the config with plugins present, which installs parsers.
export PATH="$HOME/.local/bin:$PATH"
nvim --headless "+Lazy! sync" +qa
nvim --headless +qa
nvim --headless -c 'lua require("lazy").load({ plugins = { "nvim-lspconfig" } })' -c MasonToolsInstallSync -c qa

echo
echo "Log out and pick i3 at the login screen."
