{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.cloud.traefik.dashboard;
in
{
  options.cloud.traefik.dashboard = {
    enable = mkEnableOption "Enables the Traefik Dashboard";
    usersFile = mkOption {
      type = types.path;
      description = ''
        The path to the users authentication file.
        This is passed to the basicAuth middleware, see https://doc.traefik.io/traefik/middlewares/http/basicauth/
      '';
    };
    host = mkOption {
      type = types.str;
      default = "traefik.nkagami.me";
      description = "The host to be used for the dashboard";
    };
  };

  config = mkIf cfg.enable {
    # Enable it in the static config options.
    services.traefik.staticConfigOptions.api.dashboard = true;

    # Dynamic configuration
    # ---------------------
    ## Middleware
    services.traefik.dynamicConfigOptions.http.middlewares.dashboard-auth.basicAuth.usersFile =
      cfg.usersFile;
    ## Router
    services.traefik.dynamicConfigOptions.http.routers.dashboard = {
      rule = "Host(`${cfg.host}`)";
      entryPoints = [ "https" ];
      middlewares = [ "dashboard-auth" ];
      service = "api@internal";
      tls.certResolver = "le";
    };
  };
}
