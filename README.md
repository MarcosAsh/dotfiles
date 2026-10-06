# dotfiles

Neovim, i3, shell and git config for my Ubuntu laptop, plus its backups.

## Install

```bash
git clone git@github.com:MarcosAsh/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` symlinks `nvim`, `i3`, `i3status`, `kitty`, the restic excludes and the systemd user units into `~/.config`, `bashrc` and `gitconfig` into `~`, and the scripts in `bin` into `~/.local/bin`. Anything already there gets moved aside with a `.bak` suffix rather than overwritten.

## Neovim

Needs Neovim 0.12 or newer (Ubuntu's apt package is too old, use the release tarball), plus `ripgrep` for Telescope's live grep and `make` to build `telescope-fzf-native`. `fd` is optional but makes file finding faster. `bear` generates `compile_commands.json` for clangd in Makefile projects like FFmpeg (`bear -- make`), and `zathura` is the PDF viewer for vimtex.

```bash
sudo apt install ripgrep fd-find build-essential bear zathura
```

nvim-treesitter is on its `main` branch, which compiles parsers with the tree-sitter CLI:

```bash
curl -fL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
    | gunzip > ~/.local/bin/tree-sitter && chmod +x ~/.local/bin/tree-sitter
```

Plugins are managed by lazy.nvim, which bootstraps itself on first launch. Versions are pinned in `nvim/lazy-lock.json`.

Language servers, stylua and codelldb are installed by mason on startup. Three things come from elsewhere:

- `ocamllsp` comes from opam so it matches the OxCaml switch: `opam install ocaml-lsp-server.1.19.0+ox2`
- `clang-format` comes from `uv tool install clang-format`, since mason builds it in a venv and that needs `python3-venv` from apt
- `gofmt` and `rustfmt` come with Go and rustup

Formatting runs on `:w` through conform, but only where the project has a config for it (`.clang-format`, `pyproject.toml`/`ruff.toml`, `.ocamlformat`, `stylua.toml`), so upstream code without one is left alone. Autosave never formats. `:FormatToggle` turns it off for the session. Indentation is detected per file by vim-sleuth.

Debugging C, C++ and Rust goes through nvim-dap and codelldb. `F5` starts or continues, `F10`/`F11`/`F12` step over, in and out, `<leader>db` sets a breakpoint.

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

## Displays

`bin/display-watch` runs from the i3 config and listens for monitor hotplug events. `bin/display-auto` does the actual switching:

| | outputs | `Xft.dpi` |
| --- | --- | --- |
| docked | external monitor only, laptop panel off | 96 |
| on the go | laptop panel only | 144 |

The laptop panel is about 257 dpi and the desk monitor about 110, so a flat 96 dpi makes text tiny on the laptop. Since only one screen is ever lit, one global DPI per mode is enough. Changing it restarts i3 in place, which keeps the window layout. Apps that were already open keep their old font size until relaunched, and dmenu ignores `Xft.dpi` entirely. Adjust `LAPTOP_DPI` at the top of `bin/display-auto` to taste.

To override by hand:

```bash
display-auto both      # laptop plus monitor, side by side
display-auto laptop    # laptop only, even while docked
display-auto monitor   # monitor only
display-auto auto      # back to deciding automatically
```

An override sticks until the next real dock or undock.

Note that i3 only re-runs `exec_always` on restart, not on reload, so use `Super+Shift+r` after changing this.

## Font

Both configs assume JetBrainsMono Nerd Font.

```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o JetBrainsMono.zip && rm JetBrainsMono.zip
fc-cache -f
```

## Power

`bin/power-auto watch` runs from the i3 config and switches the power-profiles-daemon profile whenever a charger is plugged in or pulled out: `performance` on AC, `power-saver` on battery. Change `AC_PROFILE` and `BATTERY_PROFILE` at the top of the script to taste. Framework recommends power-profiles-daemon over TLP on Core Ultra machines, so keep TLP off.

`powerprofilesctl set <profile>` still works by hand. It holds until the next plug or unplug.

## Backups

`bin/backup` runs restic against a repo on the gaming PC (`marcos@192.168.0.219:~/backups/bombopulus`) over SFTP. The `restic-backup` timer runs it every 4 hours and `restic-prune` cleans up on Sundays. Both skip when the laptop is on battery or the gaming PC isn't reachable, so being away from home doesn't leave failed units. Snapshots are kept hourly for a day, then daily for 2 weeks, weekly for 2 months and monthly for a year.

restic isn't in apt on this machine, so it comes from the release:

```bash
v=0.19.1
curl -fLO https://github.com/restic/restic/releases/download/v$v/restic_${v}_linux_amd64.bz2
bunzip2 restic_${v}_linux_amd64.bz2 && install -m 755 restic_${v}_linux_amd64 ~/.local/bin/restic
```

The repo password lives in `~/.config/restic/password` and is deliberately not in this repo. Keep a copy somewhere else, because without it the backups can't be read.

`restic/excludes` leaves out anything that can be downloaded or rebuilt: caches, `Downloads`, the Xilinx install, toolchains, `node_modules` and virtualenvs. Cargo `target` directories are skipped through `--exclude-caches`.

Anything after `backup` other than `run` or `prune` goes straight to restic:

```bash
backup snapshots
backup restore latest --target /tmp/restore --include ~/dev/some-project
systemctl --user start restic-backup     # back up now
journalctl --user -u restic-backup       # see how the last run went
```
