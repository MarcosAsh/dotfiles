# Dell OptiPlex 7040 Micro, i5-6500T, 16 GB. Replaces Proxmox. The k3s server, and
# owns the iGPU, so Jellyfin lands here.
{ config, lib, pkgs, ... }:

let
  # Game mode on the gaming PC (hosts/gaming-pc/gaming.nix) drains and uncordons that node
  # through this forced command. pc-queue is stopped first so its preStop can't uncordon the
  # node mid-game, and a deliberate stop doesn't count as a failed try.
  gamingNode = pkgs.writeShellScript "gaming-node" ''
    kubectl() { ${config.services.k3s.package}/bin/k3s kubectl "$@"; }
    case "$SSH_ORIGINAL_COMMAND" in
      on)
        if kubectl -n isabelle get pods -l app=pc-queue --field-selector status.phase=Running -o name | grep -q .; then
          kubectl -n isabelle exec deploy/pc-queue -- python3 scripts/pc_queue.py stop || true
        fi
        kubectl drain gaming-pc --ignore-daemonsets --delete-emptydir-data --timeout=120s
        ;;
      off) kubectl uncordon gaming-pc ;;
      *) echo "on or off" >&2; exit 1 ;;
    esac
  '';
  gameKey = ../gaming-pc/game-mode.pub;
in
{
  imports = [ ../../modules/k3s-server.nix ./disko.nix ]
    # Written by nixos-anywhere --generate-hardware-config on the first install
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "optiplex-7040";
  homelab.k3s.labels = [ "homelab/igpu=true" ];
  users.users.root.openssh.authorizedKeys.keys = lib.optional (builtins.pathExists gameKey)
    ''restrict,command="${gamingNode}",from="192.168.0.219" ${lib.fileContents gameKey}'';

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;
  # The i915 kernel driver is enough: Jellyfin's image ships its own VAAPI/QSV userspace

  # Keeps the Proxmox address, agents and Pi-hole records point at it. Matched by MAC
  # so the name the NIC gets doesn't matter. DNS is public, not Pi-hole, because
  # Pi-hole runs in this cluster.
  networking.useNetworkd = true;
  # Pi-hole runs on the host network here and serves DNS (53) and DHCP (67) for the house,
  # so resolved must not hold port 53. The box itself asks public resolvers.
  services.resolved.enable = false;
  # networkd only hands its DNS to resolved, so write resolv.conf ourselves (CoreDNS reads it)
  networking.resolvconf.enable = false;
  environment.etc."resolv.conf".text = "nameserver 1.1.1.1\nnameserver 9.9.9.9\noptions edns0\n";
  networking.firewall.allowedTCPPorts = [ 53 80 443 8081 ];
  networking.firewall.allowedUDPPorts = [ 53 67 123 ];
  # Subnet router for the house, so home.arpa works away from home. Join with
  # `tailscale up --advertise-routes=192.168.0.0/24`, then approve the route in the admin page.
  services.tailscale.useRoutingFeatures = "server";
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
