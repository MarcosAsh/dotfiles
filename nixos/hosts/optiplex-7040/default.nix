# Dell OptiPlex 7040 Micro, i5-6500T, 16 GB. Replaces Proxmox. k3s agent that
# owns the iGPU, so Jellyfin lands here.
{ ... }:

{
  imports = [ ../../modules/k3s-agent.nix ./disko.nix ];

  networking.hostName = "optiplex-7040";
  homelab.k3s.labels = [ "homelab/igpu=true" ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    extraPackages = [ ];
  };
}
