{ config, pkgs, lib, ... }:

with { inherit (lib) mkEnableOption mkOption types mkIf; };
let
  cfg = config.nki.services.nix-cache;

  bindAddr = "127.0.0.1:5000";
in
{
  options.nki.services.nix-cache = {
    enableClient = mkOption {
      type = types.bool;
      default = !cfg.enableServer;
      description = "Enable nix-cache client";
    };
    enableServer = mkEnableOption "Enable nix-cache server";

    host = mkOption {
      type = types.str;
      default = "nix.home.tinc";
    };

    publicKey = mkOption {
      type = types.str;
      default = builtins.readFile ./cache-pub-key.pem;
    };

    privateKeyFile = mkOption {
      type = types.path;
      description = "Path to the private key .pem file";
    };
  };

  config = {
    nix.settings = mkIf cfg.enableClient {
      substituters = lib.mkAfter [ "http://${cfg.host}" ];
      trusted-public-keys = [ cfg.publicKey ];
    };

    services.harmonia = mkIf cfg.enableServer {
      enable = true;
      signKeyPaths = [ cfg.privateKeyFile ];
      settings = {
        bind = bindAddr;
        priority = 45;
      };
    };

    services.nginx = mkIf cfg.enableServer {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = {
        # ... existing hosts config etc. ...
        "${cfg.host}" = {
          locations."/".proxyPass = "http://${bindAddr}";
        };
      };
    };
  };
}
