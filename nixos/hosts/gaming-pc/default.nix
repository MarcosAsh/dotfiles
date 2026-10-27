# bombopulus-pro: RTX 5070 Ti, 1 TB Crucial P3 root, Samsung 980 as the backup disk.
# k3s GPU agent, NFS server for the media library.
{ config, lib, pkgs, ... }:

{
  imports = [ ../../modules/k3s-agent.nix ./disko.nix ]
    # Written by nixos-anywhere --generate-hardware-config on the first install
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "gaming-pc";
  homelab.k3s.labels = [ "homelab/gpu=nvidia" ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];
  hardware.cpu.amd.updateMicrocode = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    open = true; # Blackwell only works with the open modules
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    nvidiaSettings = false; # GUI tool, headless box
    # Keeps the driver loaded so the idle card sits in P8 instead of re-initialising per job
    nvidiaPersistenced = true;
  };
  hardware.nvidia-container-toolkit.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Jellyfin mounts the NFS share by this address
  networking.useNetworkd = true;
  systemd.network.networks."10-lan" = {
    matchConfig.MACAddress = "74:56:3c:7c:57:05";
    address = [ "192.168.0.219/24" ];
    gateway = [ "192.168.0.1" ];
    dns = [ "1.1.1.1" "9.9.9.9" ];
  };

  # The Samsung 980, kept across the reinstall. Mounted by filesystem UUID, never formatted.
  fileSystems."/srv/pve-backup" = {
    device = "/dev/disk/by-uuid/2f5e8b1e-0518-4c4e-8759-6ea7c5eebf25";
    fsType = "ext4";
    options = [ "noatime" "nofail" ];
  };

  # Jellyfin reads the library over NFS, same export as today
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/media/library 192.168.0.0/24(ro,no_subtree_check,all_squash)
    '';
  };
  networking.firewall.allowedTCPPorts = [ 2049 ];
}
