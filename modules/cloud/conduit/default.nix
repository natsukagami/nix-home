{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.cloud.conduit;

  defaultConfig = {
    global = {
      # Must be filled
      # server_name = "";
      # Must be filled
      # port = "";
      max_request_size = 20000000;
      allow_registration = false;
      allow_encryption = true;
      allow_federation = true;
      trusted_servers = [ "matrix.org" ];
      address = "::1";
      # Must be filled
      # database_path = "";
      database_backend = "rocksdb";
    };
  };
in
with lib;
{
  imports = [ ./heisenbridge.nix ];
  options.cloud.conduit = {
    enable = mkEnableOption "Enable the conduit server";

    package = mkOption {
      type = types.package;
      default = pkgs.matrix-conduit;
    };

    instances = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            host = mkOption {
              type = types.str;
            };
            server_name = mkOption {
              type = types.str;
              default = "";
            };
            port = mkOption {
              type = types.int;
            };
            noCloudflare = mkOption {
              type = types.bool;
              default = false;
            };
            allow_registration = mkOption {
              type = types.bool;
              default = false;
            };
            well-known_port = mkOption {
              type = types.int;
            };
          };
        }
      );
    };
  };

  config.systemd.services = mkIf cfg.enable (
    lib.attrsets.mapAttrs' (
      name: instance:
      lib.attrsets.nameValuePair "matrix-conduit-${name}" (
        let
          srvName = "matrix-conduit-${name}";
          format = pkgs.formats.toml { };
          server_name = if instance.server_name == "" then instance.host else instance.server_name;
          configFile = format.generate "conduit.toml" (
            lib.attrsets.recursiveUpdate defaultConfig {
              global.server_name = server_name;
              global.port = instance.port;
              global.allow_registration = instance.allow_registration;
              global.database_path = "/mnt/data/${srvName}/";
              global.well_known_client = "https://${instance.host}";
              global.well_known_server = "${instance.host}:443";
            }
          );
        in
        {
          description = "Conduit Matrix Server (for ${server_name})";
          documentation = [ "https://gitlab.com/famedly/conduit/" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            CONDUIT_CONFIG = configFile;
          };
          serviceConfig = {
            DynamicUser = true;
            User = "${srvName}";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            PrivateDevices = true;
            PrivateMounts = true;
            PrivateUsers = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@privileged"
            ];
            # StateDirectory = "/mnt/data/${srvName}";
            BindPaths = [ "/mnt/data/${srvName}" ];
            ExecStart = "${cfg.package}/bin/conduit";
            Restart = "on-failure";
            RestartSec = 10;
            StartLimitBurst = 5;
          };
        }
      )
    ) cfg.instances
  );

  config.cloud.traefik.hosts = mkIf cfg.enable (
    (lib.attrsets.mapAttrs' (
      name: instance:
      lib.attrsets.nameValuePair "conduit-${name}" ({
        inherit (instance) host port noCloudflare;
      })
    ) cfg.instances)
  );
}
