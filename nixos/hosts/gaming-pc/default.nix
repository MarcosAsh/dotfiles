# bombopulus-pro: RTX 5070 Ti, 1 TB Crucial P3 root, Samsung 980 as the backup disk.
# k3s GPU agent, NFS server for the media library.
{ config, lib, pkgs, ... }:

{
  imports = [ ../../modules/k3s-agent.nix ./disko.nix ./pe-bench.nix ]
    # Written by nixos-anywhere --generate-hardware-config on the first install
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "gaming-pc";

  # The Crucial P3 drops off the bus in its deep NVMe power states (took the PC down twice on
  # 27 Sep 2026). Keep APST off and don't let powertop touch this box.
  boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ];
  powerManagement.powertop.enable = lib.mkForce false;
  homelab.k3s.labels = [ "homelab/gpu=nvidia" "gpu=nvidia" ];

  # The cluster backup (cluster/backups in the homelab repo) writes its restic repo here over
  # sftp. Its key only does sftp and only from the OptiPlex. create-secret.sh writes the .pub.
  users.users.marcos.openssh.authorizedKeys.keys = lib.optional (builtins.pathExists ./cluster-backup.pub)
    ''restrict,command="internal-sftp",from="192.168.0.156" ${lib.fileContents ./cluster-backup.pub}'';

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
  # k3s registers the nvidia and nvidia-cdi runtimes when it finds these on its PATH.
  # nvidia-cdi injects the driver from the CDI spec NixOS writes to /var/run/cdi.
  systemd.services.k3s.path = [ pkgs.nvidia-container-toolkit.tools ];
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

  # Library folder, owned by marcos so downloads can land there
  systemd.tmpfiles.rules = [ "d /srv/media/library 0755 marcos users -" "d /srv/media/library/Movies 0755 marcos users -" ];

  # Jellyfin reads the library over NFS, same export as today
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/media/library 192.168.0.0/24(ro,no_subtree_check,all_squash)
    '';
  };
  networking.firewall.allowedTCPPorts = [ 2049 9835 ];

  # GPU power cap while the case runs hot (gpu-power-cap.py), set again at every boot
  systemd.services.gpu-power-cap = {
    description = "Cap the GPU at 250 W and 2400 MHz";
    wantedBy = [ "multi-user.target" ];
    after = [ "nvidia-persistenced.service" ];
    environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.python3.withPackages (p: [ p.nvidia-ml-py ])}/bin/python3 -u ${./gpu-power-cap.py}";
    };
  };

  # GPU exporter for Prometheus on :9835 (gpu-exporter.py). nvidia-smi segfaults on this
  # driver build, so it reads NVML directly. Root so it can name the pod or service behind
  # each GPU process.
  systemd.services.gpu-exporter = {
    description = "Prometheus exporter for the GPU through NVML";
    wantedBy = [ "multi-user.target" ];
    after = [ "nvidia-persistenced.service" ];
    environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    serviceConfig = {
      ExecStart = "${pkgs.python3.withPackages (p: [ p.nvidia-ml-py ])}/bin/python3 -u ${./gpu-exporter.py}";
      Restart = "always";
      RestartSec = 10;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };
}
