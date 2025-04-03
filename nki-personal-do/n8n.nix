{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;

  host = "n8n.dtth.ch";
  db = "n8n";
  user = db;
  port = 23412;

  dataFolder = "/mnt/data/n8n";

  plugins = pkgs.callPackage ./n8n/plugins/package.nix { };
in
{
  sops.secrets."n8n/env" = {
    reloadUnits = [ "n8n.service" ];
  };
  cloud.postgresql.databases = [ db ];
  cloud.traefik.hosts.n8n = {
    inherit port host;
  };

  # users
  users.users."${user}" = {
    group = "${user}";
    isSystemUser = true;
  };
  users.groups."${user}" = { };

  services.n8n = {
    enable = true;
    webhookUrl = "https://${host}";
  };

  systemd.services.n8n = {
    environment = {
      # Database
      DB_TYPE = "postgresdb";
      DB_POSTGRESDB_DATABASE = db;
      DB_POSTGRESDB_HOST = "/var/run/postgresql";
      DB_POSTGRESDB_USER = db;
      # Deployment
      N8N_EDITOR_BASE_URL = "https://${host}";
      N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
      N8N_USER_FOLDER = lib.mkForce dataFolder;
      HOME = lib.mkForce dataFolder;
      N8N_HOST = host;
      N8N_PORT = toString port;
      N8N_LISTEN_ADDRESS = "127.0.0.1";
      N8N_HIRING_BANNER_ENABLED = "false";
      N8N_PROXY_HOPS = "1";
      # Logs
      N8N_LOG_LEVEL = "debug";
      # License
      N8N_HIDE_USAGE_PAGE = "true";
      # Security
      N8N_BLOCK_ENV_ACCESS_IN_NODE = "true";
      # Timezone
      GENERIC_TIMEZONE = "Europe/Berlin";
    };
    serviceConfig = {
      EnvironmentFile = [ secrets."n8n/env".path ];
      User = user;
      DynamicUser = lib.mkForce false;
      ReadWritePaths = [ dataFolder ];
      # ReadOnlyPaths = [ "/var/run/postgresql" ];
    };
    unitConfig.RequiresMountsFor = [ dataFolder ];
  };
  systemd.tmpfiles.settings."10-n8n" = {
    ${dataFolder}.d = {
      user = user;
      group = user;
      mode = "0700";
    };
    "${dataFolder}/.n8n/nodes"."L+" = {
      argument = "${plugins}";
    };
  };
}
