# Dell OptiPlex 3090 Micro, i5-10500T, 256 GB NVMe. First k3s server.
{ ... }:

{
  imports = [ ../../modules/k3s-server.nix ./disko.nix ];

  networking.hostName = "homelab";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;

  # Only used by `nixos-rebuild build-vm`, for testing on the laptop
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
    diskSize = 20480;
    graphics = false;
    forwardPorts = [ { from = "host"; host.address = "127.0.0.1"; host.port = 2222; guest.port = 22; } ];
  };
}
