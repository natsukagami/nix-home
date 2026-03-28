{ pkgs, config, ... }:
{
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    mediaLocation = "/mnt/immich";
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
}
