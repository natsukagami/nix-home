{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.cloud.gotosocial;

  dbUser = "gotosocial";

  configFile = pkgs.writeText "config.yml" (generators.toYAML { } {
    # General
    host = cfg.host;
    account-domain = cfg.accountDomain;
    bind-address = "localhost";
    port = cfg.port;
    # Database
    db-port = 0; # Use socket
    db-user = dbUser;
    db-database = dbUser;
    # Web
    web-template-base-dir = "${cfg.package}/share/web/template";
    web-asset-base-dir = "${cfg.package}/share/web/assets";
    # OIDC
    oidc-enabled = true;
    oidc-idp-name = "DTTH";
    oidc-scopes = [ "openid" "email" "profile" ];
    # HTTP Client
    http-client.block-ips = [ "11.0.0.0/24" ];
    # Advanced
    advanced-rate-limit-requests = 0;
    # instance-inject-mastodon-version = true;
  });
in
{
  options.cloud.gotosocial = {
    enable = mkEnableOption "Enable our local GtS server";
    package = mkPackageOption pkgs "gotosocial-bin" { };
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
    systemd.services.gotosocial = {
      after = [ "network.target" ];
      serviceConfig = {
        User = dbUser;
        Group = dbUser;
        ExecStart = "${cfg.package}/bin/gotosocial --config-path ${configFile} server start";
        EnvironmentFile = cfg.envFile;
        # Sandboxing options to harden security
        # Details for these options: https://www.freedesktop.org/software/systemd/man/systemd.exec.html
        NoNewPrivileges = "yes";
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
        RestrictNamespaces = "yes";
        RestrictRealtime = "yes";
        DevicePolicy = "closed";
        ProtectSystem = "full";
        ProtectControlGroups = "yes";
        ProtectKernelModules = "yes";
        ProtectKernelTunables = "yes";
        LockPersonality = "yes";
        SystemCallFilter = "~@clock @debug @module @mount @obsolete @reboot @setuid @swap";

        # Denying access to capabilities that should not be relevant
        # Doc: https://man7.org/linux/man-pages/man7/capabilities.7.html
        CapabilityBoundingSet = strings.concatStringsSep " " [
          "CAP_RAWIO CAP_MKNOD"
          "CAP_AUDIT_CONTROL CAP_AUDIT_READ CAP_AUDIT_WRITE"
          "CAP_SYS_BOOT CAP_SYS_TIME CAP_SYS_MODULE CAP_SYS_PACCT"
          "CAP_LEASE CAP_LINUX_IMMUTABLE CAP_IPC_LOCK"
          "CAP_BLOCK_SUSPEND CAP_WAKE_ALARM"
          "CAP_SYS_TTY_CONFIG"
          "CAP_MAC_ADMIN CAP_MAC_OVERRIDE"
          "CAP_NET_ADMIN CAP_NET_BROADCAST CAP_NET_RAW"
          "CAP_SYS_ADMIN CAP_SYS_PTRACE CAP_SYSLOG "
        ];
        # You might need this if you are running as non-root on a privileged port (below 1024)
        #AmbientCapabilities=CAP_NET_BIND_SERVICE
        StateDirectory = "gotosocial";
        WorkingDirectory = "/var/lib/gotosocial";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "minio.service" "postgresql.service" ];
    };
  };
}
