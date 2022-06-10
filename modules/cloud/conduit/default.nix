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
  };

  config.services.matrix-conduit = mkIf cfg.enable {
    enable = true;

    settings.global = {
      inherit (cfg) port allow_registration;
      server_name = cfg.host;
      database_backend = "rocksdb";
    };
  };

  config.cloud.traefik.hosts.conduit = mkIf cfg.enable {
    inherit (cfg) port host;
  };
}

