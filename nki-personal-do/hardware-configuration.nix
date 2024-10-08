{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
  # swap
  swapDevices = [{ device = "/var/swapfile"; size = 4 * 1024; priority = 1024; }];
  zramSwap.enable = true;
  # volumes
  fileSystems.data = {
    device = "/dev/disk/by-id/scsi-0HC_Volume_31812942";
    fsType = "ext4";
    mountPoint = "/mnt/data";
  };
}
