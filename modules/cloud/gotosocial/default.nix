{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.cloud.gotosocial;

  dbUser = "gotosocial";
in
{
  options.cloud.gotosocial = {
    enable = mkEnableOption "Enable our local GtS server";
    package = mkPackageOption pkgs "gotosocial" { };
    host = mkOption {
      type = types.str;
      description = "The GtS host";
      default = "gts.dtth.ch";
    };
    accountDomain = mkOption {
      type = types.str;
      description = "The GtS account domain";
      default = "dtth.ch";
    };
    port = mkOption {
      type = types.int;
      description = "The port to listen to";
      default = 10010;
    };
    envFile = mkOption {
      type = types.str;
      description = "Additional environment variables to pass, as a file";
    };
  };

  config = mkIf cfg.enable {
    # System user
    users.users."${dbUser}" = {
      group = "${dbUser}";
      isSystemUser = true;
    };
    users.groups."${dbUser}" = { };
    # Postgres
    cloud.postgresql.databases = [ dbUser ];
    # Traefik
    cloud.traefik.hosts = { gotosocial = { inherit (cfg) host port; }; } //
      (if cfg.accountDomain != cfg.host && cfg.accountDomain != "" then {
        gotosocial-wellknown = {
          inherit (cfg) port;
          filter = "Host(`${cfg.accountDomain}`) && (PathPrefix(`/.well-known/webfinger`) || PathPrefix(`/.well-known/nodeinfo`) || PathPrefix(`/.well-known/host-meta`))";
        };
      } else { });
    # The service itself
    services.gotosocial = {
      enable = true;
      package = cfg.package;
      environmentFile = cfg.envFile;
      settings = {
        # General
        host = cfg.host;
        account-domain = cfg.accountDomain;
        bind-address = "localhost";
        port = cfg.port;
        # Instance
        instance-languages = [ "en-ca" "vi" ];
        # Accounts
        accounts-registration-open = false;
        accounts-allow-custom-css = true;
        # Database
        db-type = "postgres";
        db-address = "/run/postgresql"; # Use socket
        db-user = dbUser;
        db-database = dbUser;
        # Web
        web-template-base-dir = "${cfg.package}/share/gotosocial/web/template";
        web-asset-base-dir = "${cfg.package}/share/gotosocial/web/assets";
        # Media
        media-emoji-remote-max-size = 256 * 1024 /* bytes */;
        media-emoji-local-max-size = 256 * 1024 /* bytes */;
        # OIDC
        oidc-enabled = true;
        oidc-idp-name = "DTTH";
        oidc-scopes = [ "openid" "email" "profile" ];
        # HTTP Client
        http-client.block-ips = [ "11.0.0.0/24" ];
        # Advanced
        advanced-rate-limit-requests = 0;
        # instance-inject-mastodon-version = true;
      };
    };
    systemd.services.gotosocial.requires = mkAfter [ "minio.service" "postgresql.service" ];
    systemd.services.gotosocial.after = mkAfter [ "minio.service" "postgresql.service" ];
  };
}
