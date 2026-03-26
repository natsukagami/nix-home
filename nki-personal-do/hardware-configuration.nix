{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  # swap
  swapDevices = [
    {
      device = "/mnt/data/swapfile";
      size = 4 * 1024;
      priority = 1024;
    }
  ];
  # Zswap
  boot.kernelParams = [
    "zswap.enabled=1" # enables zswap
    "zswap.compressor=zstd" # compression algorithm
    "zswap.max_pool_percent=40" # maximum percentage of RAM that zswap is allowed to use
    "zswap.shrinker_enabled=1" # whether to shrink the pool proactively on high memory pressure    ];
  ];
  # volumes
  services.btrfs.autoScrub.enable = true;
  fileSystems.data = {
    device = "/dev/disk/by-id/scsi-0HC_Volume_101470796";
    fsType = "btrfs";
    mountPoint = "/mnt/data";
    options = [ "compress=zstd" ];
  };
}
