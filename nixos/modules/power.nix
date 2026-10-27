# Low idle power for always-on boxes. Each host adds nothing; this is imported by common.nix.
{ lib, ... }:

{
  # Sets runtime PM, SATA ALPM, audio codec power save and the rest of powertop's list
  powerManagement.powertop.enable = true;

  services.udev.extraRules = ''
    # CPU prefers efficiency over peak clocks (amd-pstate-epp and intel_pstate both honour this)
    SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/energy_performance_preference}="balance_power"
    # powertop also autosuspends the NIC, which drops the link on r8169 and e1000e. Keep wired NICs awake.
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", ATTR{device/power/control}="on"
  '';
  powerManagement.powertop.postStart = ''
    for d in /sys/class/net/en*/device/power/control; do echo on > "$d"; done
  '';

  # No radios on servers. The gaming PC's wifi card is unused, the 3090's AX201 too.
  hardware.bluetooth.enable = false;
  networking.wireless.enable = false;
  boot.blacklistedKernelModules = [ "iwlwifi" "mt7921e" "bluetooth" "btusb" ];

  # Fewer wakeups from timers that only matter on a laptop or desktop
  services.fstrim.enable = true;
  services.fwupd.enable = false;
}
