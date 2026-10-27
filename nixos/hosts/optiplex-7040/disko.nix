# Wipes the whole device. Proxmox is on it today, so only apply after the guests are no longer needed.
{ ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-PM951_NVMe_SAMSUNG_256GB__S29NNXAH118607";
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
