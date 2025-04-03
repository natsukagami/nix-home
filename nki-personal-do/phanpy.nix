{
  config,
  pkgs,
  lib,
  ...
}:
let
  host = "social.dtth.ch";
  port = 61010;
in
{
  cloud.traefik.hosts.phanpy = { inherit host port; };
  services.nginx.virtualHosts.phanpy = {
    listen = [
      {
        inherit port;
        addr = "127.0.0.1";
      }
    ];
    root = "${pkgs.dtth-phanpy}/lib/phanpy";
  };
}
