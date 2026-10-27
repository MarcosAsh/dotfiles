# bombopulus-pro: RTX 5070 Ti, 1 TB Crucial P3 root, Samsung 980 as the backup disk.
# k3s GPU agent, NFS server for the media library.
{ config, lib, pkgs, ... }:

{
  imports = [ ../../modules/k3s-agent.nix ./disko.nix ];

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
  };
  hardware.nvidia-container-toolkit.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Jellyfin reads the library over NFS, same export as today
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/media/library 192.168.0.0/24(ro,no_subtree_check,all_squash)
    '';
  };
  networking.firewall.allowedTCPPorts = [ 2049 ];
}
