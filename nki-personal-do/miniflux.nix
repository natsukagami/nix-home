{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  user = "miniflux";
  host = "rss.dtth.ch";
  port = 10020;

  secrets = config.sops.secrets;

  configEnv = builtins.mapAttrs (name: value: toString value) {
    DEBUG = "on";
    DATABASE_URL = "user=${user} dbname=${user} sslmode=disable host=/run/postgresql";
    RUN_MIGRATIONS = 1;
    LISTEN_ADDR = "127.0.0.1:${toString port}";
    BASE_URL = "https://${host}";
    HTTPS = true;

    OAUTH2_PROVIDER = "oidc";
    OAUTH2_CLIENT_ID = "oYF8Y815kQNuuYYdACJmm3kD1hzniMe6fJIDRUfs";
    OAUTH2_REDIRECT_URL = "https://${host}/oauth2/oidc/callback";
    OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.dtth.ch/application/o/rss/";
    OAUTH2_USER_CREATION = 1;

    LOG_DATE_TIME = true;

    FETCH_YOUTUBE_WATCH_TIME = true;
  };

  package = pkgs.miniflux;
in
{
  sops.secrets."miniflux/oidc-client-secret" = { };
  sops.secrets."miniflux/pocket-consumer-key" = { };
  sops.secrets."miniflux/admin-creds" = { };

  cloud.postgresql.databases = [ user ];

  cloud.traefik.hosts.miniflux = {
    inherit port host;
  };

  systemd.services.miniflux = {
    description = "Miniflux service";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "postgresql.service"
    ];
    requires = [ "postgresql.service" ];

    serviceConfig = {
      ExecStart = "${package}/bin/miniflux";
      User = user;
      DynamicUser = true;
      RuntimeDirectory = "miniflux";
      RuntimeDirectoryMode = "0700";
      EnvironmentFile = [
        secrets."miniflux/admin-creds".path
        secrets."miniflux/oidc-client-secret".path
        secrets."miniflux/pocket-consumer-key".path
      ];
      # Hardening
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
      UMask = "0077";
    };

    environment = configEnv;
  };
}
