{
  description = "Portable NixOS USB, plus the k3s homelab (one flake, shared modules, one file per host)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";
      host = name: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ disko.nixosModules.disko ./modules/common.nix ./hosts/${name} ];
      };
    in
    {
      nixosConfigurations = {
        nixusb = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hardware.nix ./configuration.nix ];
        };

        # First k3s server, the Dell OptiPlex 3090 Micro
        homelab = host "homelab";
        # k3s GPU agent, NFS media export, backup disk
        gaming-pc = host "gaming-pc";
        # k3s agent with the iGPU for Jellyfin, replaces Proxmox
        optiplex-7040 = host "optiplex-7040";
      };
    };
}
