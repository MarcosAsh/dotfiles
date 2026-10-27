# Dell OptiPlex 3090 Micro, i5-10500T, 256 GB NVMe. k3s agent, joins the server on the 7040.
{ lib, ... }:

{
  imports = [ ../../modules/k3s-agent.nix ./disko.nix ]
    # Written by nixos-anywhere --generate-hardware-config on the first install
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "homelab";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;

}
