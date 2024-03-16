{ cfg, lib, pkgs, ... }:
let
  secrets = config.sops.secrets;

  host = "peertube.dtth.ch";
  port = 19878;
in
{
  # database
  cloud.postgresql.databases = [ "peertube" ];
  # traefik
  cloud.traefik.hosts.peertube = {
    inherit port host;
  };

  services.peertube = {
    enable = true;
    enableWebHttps = true;
    listenWeb = "443";
    listenHttp = port;
    localDomain = host;

    # Databases
    redis.createLocally = true;
    database = {
      host = "/run/postgresql";
    };
  };
}

