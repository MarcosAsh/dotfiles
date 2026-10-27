# Wipes the Crucial P3 only. The Samsung 980 (the backup copy) is NOT listed here.
# By serial, not /dev/nvmeXnY: on this board the 980 is nvme0n1 and the Crucial is nvme1n1.
{ ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_2311E6BA8523";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; mountOptions = [ "umask=0077" ]; };
        };
        root = {
          size = "100%";
          content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; mountOptions = [ "noatime" ]; };
        };
      };
    };
  };
}
