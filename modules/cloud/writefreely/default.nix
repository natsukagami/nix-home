{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.cloud.writefreely;
in
{
  options.cloud.writefreely = {
    enable = mkEnableOption "Enable the write.as instance";
    package = mkOption {
      type = types.package;
      default = pkgs.writefreely;
      description = "The writefreely package to use";
    };
    host = mkOption {
      type = types.str;
      default = "write.nkagami.me";
      description = "The hostname for the instance";
    };
    site.title = mkOption {
      type = types.str;
      default = "Kagami's Writings";
      description = "The site's title";
    };
    site.description = mkOption {
      type = types.str;
      default = "Just random Kagami thoughts in written form.";
      description = "The site's description";
    };
  };

  config = mkIf cfg.enable (
    let
      host = cfg.host;
      port = 18074;
    in
    {
      # traefik
      cloud.traefik.hosts.writefreely = { inherit host port; };

      services.writefreely = {
        enable = true;
        package = cfg.package;

        host = cfg.host;
        settings = {
          server.port = port;
          app = {
            host = "https://${cfg.host}";
            site_name = cfg.site.title;
            site_description = cfg.site.description;
            single_user = true;
            min_username_len = 3;
            federation = true;
            public_stats = true;
            monetization = false;
          };
        };

        database.type = "sqlite3";

        admin.name = "nki";
      };
    }
  );
}

