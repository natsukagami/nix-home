{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
  # swap
  swapDevices = [{ device = "/var/swapfile"; size = 2 * 1024; }];
  # volumes
  fileSystems."/mnt/minio" = {
    device = "/dev/disk/by-id/scsi-0HC_Volume_31812942";
    fsType = "ext4";

  };
}
