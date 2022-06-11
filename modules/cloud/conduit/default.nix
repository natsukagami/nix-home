{ pkgs, config, lib, ... }:

let
  cfg = config.cloud.conduit;
in
with lib;
{
  options.cloud.conduit = {
    enable = mkEnableOption "Enable the conduit server";

    host = mkOption {
      type = types.str;
      default = "m.nkagami.me";
    };

    port = mkOption {
      type = types.int;
      default = 6167;
    };

    allow_registration = mkOption {
      type = types.bool;
      default = false;
    };

    well-known_port = mkOption {
      type = types.int;
      default = 6166;
    };
  };

  config.services.matrix-conduit = mkIf cfg.enable {
    enable = true;

    settings.global = {
      inherit (cfg) port allow_registration;
      server_name = cfg.host;
      database_backend = "rocksdb";
    };
  };

  # Serving .well-known files
  # This is a single .well-known/matrix/server file that points to the server,
  # which is NOT on port 8448 since Cloudflare doesn't allow us to route HTTPS
  # through that port.
  config.services.nginx = mkIf cfg.enable {
    enable = true;
    virtualHosts.conduit-well-kwown = {
      listen = [{ addr = "127.0.0.1"; port = cfg.well-known_port; }];
      # Check https://github.com/spantaleev/matrix-docker-ansible-deploy/blob/master/docs/configuring-well-known.md
      # for the file structure.
      root = pkgs.writeTextDir ".well-known/matrix/server" ''
        {
              "m.server": "${cfg.host}:443"
        }
      '';
    };
  };

  config.cloud.traefik.hosts = mkIf cfg.enable {
    conduit = { inherit (cfg) port host; };
    conduit-well-kwown = {
      port = cfg.well-known_port;
      filter = "Host(`${cfg.host}`) && PathPrefix(`/.well-known`)";
    };
  };
}

