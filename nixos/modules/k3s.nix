# Shared k3s settings. Import k3s-server.nix or k3s-agent.nix, not this.
{ config, lib, ... }:

{
  options.homelab.k3s = {
    serverAddr = lib.mkOption {
      type = lib.types.str;
      default = "https://192.168.0.220:6443";
      description = "API address agents join. Set to the homelab server's IP once it has one.";
    };
    tokenFile = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/k3s-token";
      description = "Shared join token. Copy it from /var/lib/rancher/k3s/server/node-token on the server.";
    };
    labels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Node labels, key=value.";
    };
  };

  config = {
    services.k3s = {
      tokenFile = config.homelab.k3s.tokenFile;
      nodeLabel = config.homelab.k3s.labels;
    };
    # API, kubelet, flannel vxlan, ssh stays open from common.nix
    networking.firewall.allowedTCPPorts = [ 6443 10250 ];
    networking.firewall.allowedUDPPorts = [ 8472 ];
  };
}
