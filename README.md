# dotfiles

Neovim and i3 config for my Ubuntu laptop.

## Install

```bash
git clone git@github.com:MarcosAsh/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` symlinks `nvim`, `i3` and `i3status` into `~/.config`. Anything already there gets moved aside with a `.bak` suffix rather than overwritten.

## Neovim

Needs Neovim 0.9 or newer, plus `ripgrep` for Telescope's live grep and `make` to build `telescope-fzf-native`. `fd` is optional but makes file finding faster.

```bash
sudo apt install ripgrep fd-find build-essential
```

Plugins are managed by lazy.nvim, which bootstraps itself on first launch. Versions are pinned in `nvim/lazy-lock.json`.

Leader is Space. Press it and wait to get the which-key menu.

| Key | |
| --- | --- |
| `<leader>ff` | find files |
| `<leader>fg` | live grep |
| `<leader>fb` | buffers |
| `<leader>ac` | toggle Claude Code |
| `<leader>as` | send selection to Claude (visual mode) |
| `<leader>n` | file tree |

Claude Code integration is `coder/claudecode.nvim` and expects the `claude` CLI on PATH.

## kitty

Installed without root by the official installer, which drops it in `~/.local/kitty.app`:

```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
ln -sfn ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
```

Config uses JetBrainsMono Nerd Font and the tokyonight palette so it matches nvim and the i3 bar. i3 is set to use it as `$term`.

## i3

X11 only, so an X server has to be present:

```bash
sudo apt install i3 xorg brightnessctl
```

Mod is Super. `Super+Return` for a terminal, `Super+d` for the launcher, `Super+Shift+r` to reload after editing.

The i3status config names this laptop's interfaces (`wlp170s0`, `enxd0c1b53f2ae5`). Change those on other hardware.

## Font

Both configs assume JetBrainsMono Nerd Font.

```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o JetBrainsMono.zip && rm JetBrainsMono.zip
fc-cache -f
```
