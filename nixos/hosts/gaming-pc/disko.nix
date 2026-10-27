# Wipes the Crucial P3 only. The Samsung 980 (the backup copy) is NOT listed here.
# Replace the device with the /dev/disk/by-id/ path from `ls -l /dev/disk/by-id` so
# a renumbered NVMe can never point this at the 980.
{ ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/REPLACE-WITH-CRUCIAL-P3-ID";
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
