{ config, lib, pkgs, ... }:

let
  user = "marcosash";
in
{
  networking.hostName = "nixusb";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.11";

  # GRUB as the removable fallback (/boot/EFI/BOOT/BOOTX64.EFI) so the stick
  # never writes to a host machine's NVRAM
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.loader.efi.canTouchEfiVariables = false;

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" "dialout" "plugdev" ];
  };

  # --- Desktop: X11 + i3, same as the laptop ---
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu i3status i3lock xss-lock feh dunst brightnessctl
        xrandr xset xrdb libnotify pavucontrol networkmanagerapplet
      ];
    };
    displayManager.lightdm.enable = true;
  };
  services.displayManager.defaultSession = "none+i3";
  services.libinput.enable = true;
  services.libinput.touchpad.naturalScrolling = false;
  services.libinput.touchpad.tapping = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true;

  services.blueman.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.tailscale.enable = true;
  services.udev.packages = [ pkgs.sigrok-firmware-fx2lafw pkgs.libsigrok ];
  virtualisation.docker.enable = true;

  # Prebuilt binaries (mason's language servers, codelldb, kitty's installer)
  # expect a normal FHS linker
  programs.nix-ld.enable = true;

  # The gitconfig calls /usr/bin/gh for the credential helper
  systemd.tmpfiles.rules = [ "L+ /usr/bin/gh - - - - /run/current-system/sw/bin/gh" ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji
  ];

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ table table-others libpinyin m17n ];
  };

  programs.zsh.enable = true;

  # --- Packages, mapped from the laptop's apt/snap/cargo installs ---
  environment.systemPackages = with pkgs; [
    # terminal and shell tools
    kitty neovim tmux htop fastfetch tree-sitter ripgrep fd tree curl wget unzip zip
    git gh restic lm_sensors yt-dlp ffmpeg-full efibootmgr cryptsetup

    # C, C++, and build tooling
    gcc clang clang-tools gnumake cmake ninja pkg-config nasm yasm automake autoconf
    libtool bear gdb lldb texinfo

    # languages
    go jdk nodejs rustup python3 uv opam mpremote

    # FPGA and EDA
    yosys nextpnr icestorm trellis verilator iverilog gtkwave kicad
    sigrok-cli pulseview glslang vulkan-tools vulkan-validation-layers arduino-cli

    # proof tools
    # isabelle is left out: the nixpkgs build runs HOL-SMT_Examples and z3 segfaults (139)
    cadical

    # apps
    google-chrome firefox obsidian vscode jetbrains.clion jetbrains.pycharm
    drawio zathura protonvpn-gui moonlight-qt rpi-imager k9s kubectl
    claude-code opencode
    texliveMedium
  ];

  # --- NVIDIA, for the gaming PC. Pick "NixOS - nvidia" in the boot menu. ---
  # Kept as a specialisation so the default entry works on Intel/AMD machines
  # without the proprietary X driver trying to claim a GPU that isn't there.
  specialisation.nvidia.configuration = {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      open = true; # Blackwell (RTX 50 series) only works with the open modules
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
  };
}
