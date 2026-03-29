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
}
