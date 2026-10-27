{ config, ... }:

{
  imports = [ ./k3s.nix ];

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = config.homelab.k3s.serverAddr;
  };
}
