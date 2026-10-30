# Game streaming. Plasma logs in on the monitor's spare input, Sunshine streams it to Moonlight
# on the laptop. Starting the Steam app runs game-mode on (drain this node, boost on, GPU clock
# up, SSH-launched jobs to idle CPU priority, /run/game-mode for other tools to check), ending
# the stream runs game-mode off. Boost stays off otherwise.
{ config, lib, pkgs, ... }:

let
  # 1800 MHz: 23 W less than 2400 on Lattice training for about 7% slower epochs (29 Oct 2026)
  batchClock = 1800;
  gameClock = 2400;

  gpuCap = pkgs.writeShellScript "gpu-cap" ''
    export LD_LIBRARY_PATH=/run/opengl-driver/lib
    exec ${pkgs.python3.withPackages (p: [ p.nvidia-ml-py ])}/bin/python3 -u ${./gpu-power-cap.py} "$@"
  '';

  gameMode = pkgs.writeShellApplication {
    name = "game-mode";
    runtimeInputs = [ pkgs.openssh pkgs.systemd pkgs.gawk pkgs.coreutils ];
    text = ''
      dir=/var/lib/game-mode
      # remote logins only, the desktop on seat0 keeps its priority
      ssh_jobs() {
        for s in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
          [ -z "$(loginctl show-session "$s" -p Seat --value)" ] || continue
          systemctl set-property --runtime "session-$s.scope" CPUWeight="$1" || true
        done
      }
      node() {
        ssh -i "$dir/id_ed25519" -o BatchMode=yes -o ConnectTimeout=5 \
          -o UserKnownHostsFile="$dir/known_hosts" -o StrictHostKeyChecking=accept-new \
          root@192.168.0.156 "$1"
      }
      case "''${1:-}" in
        on)
          touch /run/game-mode
          ssh_jobs idle
          node on || echo "could not drain gaming-pc, the jobs keep running" >&2
          echo 1 > /sys/devices/system/cpu/cpufreq/boost
          ${gpuCap} ${toString gameClock}
          ;;
        off)
          echo 0 > /sys/devices/system/cpu/cpufreq/boost
          ${gpuCap} ${toString batchClock}
          ssh_jobs 100
          rm -f /run/game-mode
          node off
          ;;
        idle) ssh_jobs idle ;;
        *)
          echo "usage: game-mode on|off|idle" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  systemd.services.gpu-power-cap = {
    description = "Cap the GPU at 250 W and ${toString batchClock} MHz";
    wantedBy = [ "multi-user.target" ];
    after = [ "nvidia-persistenced.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${gpuCap} ${toString batchClock}";
    };
  };

  # Boost costs a lot of voltage on the 5800X3D: off, it draws far less for 15-25% slower jobs
  systemd.tmpfiles.rules = [ "w /sys/devices/system/cpu/cpufreq/boost - - - - 0" ];

  # Key for draining this node through the OptiPlex (forced command there, see optiplex-7040).
  # Copy game-mode.pub into this folder after the first deploy.
  systemd.services.game-mode-key = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Type = "oneshot"; StateDirectory = "game-mode"; };
    script = ''
      [ -e /var/lib/game-mode/id_ed25519 ] ||
        ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C game-mode@gaming-pc -f /var/lib/game-mode/id_ed25519
    '';
  };
  environment.systemPackages = [ gameMode ];
  # SSH jobs started mid-game get idle priority too
  systemd.services.game-mode-idle = {
    unitConfig.ConditionPathExists = "/run/game-mode";
    serviceConfig = { Type = "oneshot"; ExecStart = "${gameMode}/bin/game-mode idle"; };
  };
  systemd.timers.game-mode-idle = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "1min"; OnUnitActiveSec = "30s"; };
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager = {
    sddm = { enable = true; wayland.enable = true; };
    autoLogin = { enable = true; user = "marcos"; };
    defaultSession = "plasma";
  };
  # It's still a server: no suspend, no screen lock on the streamed desktop, no file indexer,
  # and no power-profiles-daemon overriding the EPP set in modules/power.nix
  systemd.targets = lib.genAttrs [ "sleep" "suspend" "hibernate" "hybrid-sleep" ] (_: { enable = false; });
  environment.etc."xdg/kscreenlockerrc".text = "[Daemon]\nAutolock=false\nLockOnResume=false\n";
  # Plasma blanks DP-1 after 10 idle minutes, which disables the connector, and Sunshine's KMS
  # capture then finds no monitor and gives up until restarted (30 Oct 2026)
  environment.etc."xdg/powerdevilrc".text = ''
    [AC][Display]
    DimDisplayWhenIdle=false
    TurnOffDisplayWhenIdle=false

    [AC][SuspendAndShutdown]
    AutoSuspendAction=0
  '';
  environment.etc."xdg/baloofilerc".text = "[Basic Settings]\nIndexing-Enabled=false\n";
  services.power-profiles-daemon.enable = false;
  # modules/minimal.nix strips what a desktop needs
  services.udisks2.enable = lib.mkForce true;
  xdg = lib.genAttrs [ "icons" "mime" "sounds" "autostart" ] (_: { enable = lib.mkForce true; });
  fonts.fontconfig.enable = lib.mkOverride 49 true;

  programs.steam.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      sunshine_name = "gaming-pc";
      capture = "kms";
      # NVENC can't load libcuda under the capSysAdmin wrapper, Vulkan encode runs on the 5070 Ti too
      encoder = "vulkan";
      csrf_allowed_origins = lib.concatMapStringsSep "," (h: "https://${h}:47990")
        [ "192.168.0.219" "gaming-pc" "gaming-pc.home.arpa" ];
    };
    applications.apps = [
      { name = "Desktop"; image-path = "desktop.png"; }
      {
        name = "Steam";
        image-path = "steam.png";
        prep-cmd = [{
          do = "/run/wrappers/bin/sudo ${gameMode}/bin/game-mode on";
          undo = "/run/wrappers/bin/sudo ${gameMode}/bin/game-mode off";
        }];
        detached = [ "setsid steam steam://open/bigpicture" ];
      }
    ];
  };
}
