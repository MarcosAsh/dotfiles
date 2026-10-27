{ config, lib, pkgs, ... }:

{
  imports = [ ./k3s.nix ./argocd.nix ];

  services.k3s = {
    enable = true;
    role = "server";
    # Caddy is the front door and a LoadBalancer on 80/443, so Traefik and the
    # bundled service LB must not compete for those ports
    extraFlags = [ "--disable=traefik" "--write-kubeconfig-mode=0640" ];
  };
  # First server has no token yet: k3s makes one. Agents read it from there.
  services.k3s.tokenFile = lib.mkForce null;
}
