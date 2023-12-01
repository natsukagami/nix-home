{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.cloud.bitwarden;

  databaseUser = "bitwarden";
  databaseUrl = "postgres:///${user}?user=${user}";

  user = "bitwarden";

  port = 8001;

  host = "bw.nkagami.me";

  package = pkgs.vaultwarden-postgresql;
in
{
  options.cloud.bitwarden = {
    envFile = mkOption {
      type = types.nullOr types.path;
      description = "Path to the env file containing stuff";
      default = null;
    };
  };

  config = {
    # users
    users.users."${user}" = {
      group = "${user}";
      isSystemUser = true;
    };
    users.groups."${user}" = { };
    # database
    cloud.postgresql.databases = [ databaseUser ];
    # traefik
    cloud.traefik.hosts.bitwarden = {
      inherit port host;
      noCloudflare = true;
    };
    # systemd unit
    systemd.services.bitwarden-server = {
      after = [ "network.target" ];
      path = with pkgs; [ openssl ];
      environment = {
        SIGNUPS_ALLOWED = "false";
        DATABASE_URL = databaseUrl;

        DATA_FOLDER = "/var/lib/bitwarden-server";
        WEB_VAULT_FOLDER = "${pkgs.vaultwarden-vault}/share/vaultwarden/vault";

        ROCKET_PORT = toString port;

        PUSH_ENABLED = "true";

        DOMAIN = "https://${host}";
      };

      serviceConfig = {
        User = user;
        Group = user;
        ExecStart = "${package}/bin/vaultwarden";
        EnvironmentFile = lists.optional (cfg.envFile != null) cfg.envFile;
        LimitNOFILE = "1048576";
        PrivateTmp = "true";
        PrivateDevices = "true";
        ProtectHome = "true";
        ProtectSystem = "strict";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        StateDirectory = "bitwarden-server";
      };
      requires = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
