{ pkgs, config, ... }:
let
  port = 2283;
in
{
  services.immich = {
    inherit port;
    enable = true;
    package = pkgs.immich;
    mediaLocation = "/mnt/immich";
    accelerationDevices = null;
    settings = null;
    machine-learning.environment = {
    };
  };
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
  nki.nginx.hosts."immich" = {
    locations."/" = {
      proxyPass = "http://${config.services.immich.host}:${toString port}";
      proxyWebsockets = true;
    };
  };

  # Backup
  services.btrbk.instances.immich = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "7d";
      snapshot_preserve = "30d";

      target_preserve_min = "no";
      target_preserve = "20d 10w *m";

      snapshot_dir = "btrbk_snapshots";

      stream_compress = "zstd";

      volume."/mnt/immich" = {
        target."/mnt/immich-backup" = { };
        subvolume."." = { };
      };
    };
  };
}
