# Dell OptiPlex 7040 Micro, i5-6500T, 16 GB. Replaces Proxmox. The k3s server, and
# owns the iGPU, so Jellyfin lands here.
{ lib, ... }:

{
  imports = [ ../../modules/k3s-server.nix ./disko.nix ]
    # Written by nixos-anywhere --generate-hardware-config on the first install
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "optiplex-7040";
  homelab.k3s.labels = [ "homelab/igpu=true" ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;
  # The i915 kernel driver is enough: Jellyfin's image ships its own VAAPI/QSV userspace

  # Keeps the Proxmox address, agents and Pi-hole records point at it. Matched by MAC
  # so the name the NIC gets doesn't matter. DNS is public, not Pi-hole, because
  # Pi-hole runs in this cluster.
  networking.useNetworkd = true;
  systemd.network.networks."10-lan" = {
    matchConfig.MACAddress = "64:00:6a:79:75:c5";
    address = [ "192.168.0.156/24" ];
    gateway = [ "192.168.0.1" ];
    dns = [ "1.1.1.1" "9.9.9.9" ];
  };

  # Only used by `nixos-rebuild build-vm`, for testing on the laptop
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
    diskSize = 20480;
    graphics = false;
    forwardPorts = [ { from = "host"; host.address = "127.0.0.1"; host.port = 2222; guest.port = 22; } ];
  };
}
