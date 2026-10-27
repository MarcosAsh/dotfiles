{ config, lib, pkgs, ... }:

{
  options.homelab.sshKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGraBN/jn+4lOb7Ma0Wraw8hU1BtYM9o6iiQf8zTdzVF claude-code-keras"
    ];
    description = "Keys that can log in as root and marcos. Password login is off.";
  };

  config = {
    time.timeZone = "Europe/London";
    i18n.defaultLocale = "en_GB.UTF-8";
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.trusted-users = [ "root" "@wheel" ];
    nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 21d"; };
    system.stateVersion = "26.11";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    hardware.enableRedistributableFirmware = true;
    zramSwap.enable = true;

    users.users.marcos = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = config.homelab.sshKeys;
    };
    users.users.root.openssh.authorizedKeys.keys = config.homelab.sshKeys;
    # nixos-rebuild --target-host needs to switch as root without a tty
    security.sudo.wheelNeedsPassword = false;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    networking.networkmanager.enable = false;
    networking.useDHCP = lib.mkDefault true;
    networking.firewall.enable = true;
    networking.firewall.allowedTCPPorts = [ 22 ];
    # node-exporter is scraped by the Prometheus in the cluster
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      openFirewall = true;
      enabledCollectors = [ "systemd" ];
    };

    # Join with `sudo tailscale up` after the first boot
    services.tailscale.enable = true;

    environment.systemPackages = with pkgs; [ git vim htop tmux curl kubectl k9s ];
    environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
