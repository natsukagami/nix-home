{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.cloud.bitwarden;

  databaseUser = "bitwarden";
  databaseUrl = "postgres:///${user}?user=${user}";

  user = "bitwarden";

  port = 8001;
  notificationsPort = 8002;

  host = "bw.nkagami.me";
in
{
  options.cloud.bitwarden = { };

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
    };
    cloud.traefik.hosts.bitwarden-notifications = {
      inherit host;
      port = notificationsPort;
      path = "/notifications/hub";
    };
    # systemd unit
    systemd.services.bitwarden-server = {
      after = [ "network.target" ];
      path = with pkgs; [ openssl ];
      environment = {
        SIGNUPS_ALLOWED = "false";
        DATABASE_URL = databaseUrl;

        DATA_FOLDER = "/var/lib/bitwarden-server";
        WEB_VAULT_FOLDER = "${pkgs.unstable.vaultwarden-vault}/share/vaultwarden/vault";

        ROCKET_PORT = toString port;

        WEBSOCKET_ENABLED = "true";
        WEBSOCKET_PORT = toString notificationsPort;

        DOMAIN = "https://${host}";
      };
      serviceConfig = {
        User = user;
        Group = user;
        ExecStart = "${pkgs.unstable.vaultwarden-postgresql}/bin/vaultwarden";
        LimitNOFILE = "1048576";
        PrivateTmp = "true";
        PrivateDevices = "true";
        ProtectHome = "true";
        ProtectSystem = "strict";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        StateDirectory = "bitwarden-server";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
