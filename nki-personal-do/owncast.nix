{ pkgs, config, lib, ... }:
let
  host = "owncast.nkagami.me";
  port = 61347;
  user = "owncast";
in
{
  # traefik
  cloud.traefik.hosts.owncast = {
    inherit port host;
  };
  services.owncast = {
    inherit user port;
    listen = "0.0.0.0"; # Listen to direct IP requests too
    enable = true;
    openFirewall = true;
    dataDir = "${config.fileSystems.data.mountPoint}/owncast";
  };
}
