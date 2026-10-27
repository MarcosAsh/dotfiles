# Wipes the whole device. Check the name with `lsblk` from the installer first.
{ ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
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
