# Nothing here is specific to one machine, so the stick boots on both the
# laptop and the gaming PC. Root and boot are found by label for the same reason.
{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [
    "xhci_pci" "ahci" "nvme" "usb_storage" "uas" "sd_mod" "sdhci_pci"
    "rtsx_pci_sdmmc" "thunderbolt" "vmd" "usbhid"
  ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

  # Core Ultra and Blackwell both want a recent kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS-ROOT";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS-BOOT";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ intel-media-driver vpl-gpu-rt ];
  };

  hardware.bluetooth.enable = true;

  # Spare the flash: logs in RAM, compressed swap instead of a swap partition
  services.journald.settings.Journal.Storage = "volatile";
  zramSwap.enable = true;
}
