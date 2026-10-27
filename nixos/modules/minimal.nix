# Strip the closure to what a headless k3s node needs.
{ modulesPath, lib, pkgs, ... }:

{
  imports = [ "${modulesPath}/profiles/minimal.nix" ];

  environment.defaultPackages = lib.mkForce [ ];
  documentation.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;
  programs.command-not-found.enable = false;
  xdg.icons.enable = false;
  xdg.mime.enable = false;
  xdg.sounds.enable = false;
  fonts.fontconfig.enable = lib.mkForce false;
  services.udisks2.enable = false;
  # No channels: everything comes from the flake
  nix.channel.enable = false;
  nix.settings.auto-optimise-store = true;
  # Builds come from the flake on the laptop, so the boxes don't keep a nixpkgs copy
  nixpkgs.flake.setNixPath = false;
  nixpkgs.flake.setFlakeRegistry = false;

  # Only the firmware these machines load: Intel graphics (Jellyfin's iGPU) and the
  # gaming PC's Realtek NIC. The full linux-firmware is 825 MB.
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [
    (pkgs.runCommand "homelab-firmware" { } ''
      mkdir -p $out/lib/firmware
      for d in i915 rtl_nic; do
        cp -r ${pkgs.linux-firmware}/lib/firmware/$d $out/lib/firmware/
      done
    '')
  ];
}
