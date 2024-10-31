{ pkgs, lib, config, ... }:
let
  cfg = config.cloud.conduit.heisenbridge;
  cfgConduit = config.cloud.conduit;
in
with lib; {
  options.cloud.conduit.heisenbridge = {
    enable = mkEnableOption "Enable heisenbridge for conduit";
    package = mkPackageOption pkgs "heisenbridge" { };
    appserviceFile = mkOption {
      type = types.str;
      description = "The path to the appservice config file";
    };
    port = mkOption {
      type = types.nullOr types.int;
      description = "The port to listen to. Leave blank to just use the appserviceFile's configuration";
      default = null;
    };
    homeserver = mkOption {
      type = types.str;
      description = "The homeserver to listen to";
    };
  };
  config = mkIf cfg.enable (
    let
      cfgFile = if cfg.port == null then cfg.appserviceFile else
      pkgs.runCommand "heisenbridge-config" { } ''
        cp ${cfg.appserviceFile} $out
        ${pkgs.sd}/bin/sd '^url: .*$' "url: http://127.0.0.1:${cfg.port}"
      '';
      listenArgs = lists.optionals (cfg.port != null) [ "--listen-port" (toString cfg.port) ];
    in
    {
      systemd.services.heisenbridge = {
        description = "Matrix<->IRC bridge";
        requires = [ "matrix-conduit-nkagami.service" "matrix-synapse.service" ]; # So the registration file can be used by Synapse
        wantedBy = [ "multi-user.target" ];

        serviceConfig = rec {
          Type = "simple";
          ExecStart = lib.concatStringsSep " " (
            [
              "${cfg.package}/bin/heisenbridge"
              "-v"

              "--config"
              cfgFile
            ]
            ++ listenArgs
            ++ [ cfg.homeserver ]
          );

          # Hardening options

          User = "heisenbridge";
          Group = "heisenbridge";
          RuntimeDirectory = "heisenbridge";
          RuntimeDirectoryMode = "0700";
          StateDirectory = "heisenbridge";
          StateDirectoryMode = "0755";

          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          PrivateMounts = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          RestrictNamespaces = true;
          RemoveIPC = true;
          UMask = "0077";

          CapabilityBoundingSet = [ "CAP_CHOWN" ] ++ optional (cfg.port != null && cfg.port < 1024) "CAP_NET_BIND_SERVICE";
          AmbientCapabilities = CapabilityBoundingSet;
          NoNewPrivileges = true;
          LockPersonality = true;
          RestrictRealtime = true;
          SystemCallFilter = [ "@system-service" "~@privileged" "@chown" ];
          SystemCallArchitectures = "native";
          RestrictAddressFamilies = "AF_INET AF_INET6";
        };
      };

      users.groups.heisenbridge = { };
      users.users.heisenbridge = {
        description = "Service user for the Heisenbridge";
        group = "heisenbridge";
        isSystemUser = true;
      };
    }
  );
}

