{ pkgs, config, lib, ... }:

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
      type = types.attrsOf (types.submodule {
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
      });
    };
  };

  config.systemd.services = mkIf cfg.enable
    (lib.attrsets.mapAttrs'
      (name: instance: lib.attrsets.nameValuePair "matrix-conduit-${name}"
        (
          let
            srvName = "matrix-conduit-${name}";
            format = pkgs.formats.toml { };
            server_name = if instance.server_name == "" then instance.host else instance.server_name;
            configFile = format.generate "conduit.toml" (lib.attrsets.recursiveUpdate defaultConfig {
              global.server_name = server_name;
              global.port = instance.port;
              global.allow_registration = instance.allow_registration;
              global.database_path = "/var/lib/${srvName}/";
            });
          in
          {
            description = "Conduit Matrix Server (for ${server_name})";
            documentation = [ "https://gitlab.com/famedly/conduit/" ];
            wantedBy = [ "multi-user.target" ];
            environment = { CONDUIT_CONFIG = configFile; };
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
              RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              SystemCallArchitectures = "native";
              SystemCallFilter = [
                "@system-service"
                "~@privileged"
              ];
              StateDirectory = "${srvName}";
              ExecStart = "${cfg.package}/bin/conduit";
              Restart = "on-failure";
              RestartSec = 10;
              StartLimitBurst = 5;
            };
          }
        ))
      cfg.instances);

  # Serving .well-known files
  # This is a single .well-known/matrix/server file that points to the server,
  # which is NOT on port 8448 since Cloudflare doesn't allow us to route HTTPS
  # through that port.
  config.services.nginx = mkIf cfg.enable
    {
      enable = true;
      virtualHosts = lib.attrsets.mapAttrs'
        (name: instance: lib.attrsets.nameValuePair "conduit-${name}-well-known" {
          listen = [{ addr = "127.0.0.1"; port = instance.well-known_port; }];
          # Check https://github.com/spantaleev/matrix-docker-ansible-deploy/blob/master/docs/configuring-well-known.md
          # for the file structure.
          root = pkgs.symlinkJoin
            {
              name = "well-known-files-for-conduit-${name}";
              paths = [
                (pkgs.writeTextDir ".well-known/matrix/client" (builtins.toJSON {
                  "m.homeserver".base_url = "https://${instance.host}";
                  "org.matrix.msc3575.proxy".url = "https://${instance.host}";
                }))
                (pkgs.writeTextDir ".well-known/matrix/server" (builtins.toJSON {
                  "m.server" = "${instance.host}:443";
                }))
              ];
            };
          # Enable CORS from anywhere since we want all clients to find us out
          extraConfig = ''
            add_header 'Access-Control-Allow-Origin' "*";
          '';
        })
        cfg.instances;
    };

  config.cloud.traefik.hosts = mkIf cfg.enable (
    (lib.attrsets.mapAttrs'
      (name: instance: lib.attrsets.nameValuePair "conduit-${name}" ({
        inherit (instance) host port noCloudflare;
      }))
      cfg.instances)
    // (lib.attrsets.mapAttrs'
      (name: instance: lib.attrsets.nameValuePair "conduit-${name}-well-known" (
        let
          server_name = if instance.server_name == "" then instance.host else instance.server_name;
        in
        {
          port = instance.well-known_port;
          filter = "Host(`${server_name}`) && PathPrefix(`/.well-known`)";
        }
      ))
      cfg.instances)
  );
}

