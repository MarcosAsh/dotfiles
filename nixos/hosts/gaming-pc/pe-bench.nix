# The protocol-emulator carrier bench on USB (cluster/pe-bench in the homelab repo): stable
# names for the Icepi and the two Picos, and access for marcos (uid 1000, as the bench pod
# runs) through dialout. Raw USB too, for openFPGALoader's FTDI, the fx2lafw analysers,
# which renumerate once sigrok loads their firmware, and the Picos' bootloader.
{ ... }:

{
  users.users.marcos.extraGroups = [ "dialout" ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", ATTRS{serial}=="DK0GEHFH", SYMLINK+="pe-icepi", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{serial}=="e66548545717552e", SYMLINK+="pe-pico-a", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{serial}=="e66548545740ad29", SYMLINK+="pe-pico-b", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6015", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0925", ATTR{idProduct}=="3881", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="608c", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", GROUP="dialout", MODE="0660"
  '';
}
