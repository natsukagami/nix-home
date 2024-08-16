{ config, pkgs, lib, ... }:

with { inherit (lib) mkEnableOption mkOption types mkIf; };
let
  cfg = config.nki.services.nix-cache;
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
      substituters = [ cfg.host ];
      trusted-public-keys = [ cfg.publicKey ];
    };

    services.nix-serve = mkIf cfg.enableServer {
      enable = true;
      secretKeyFile = cfg.privateKeyFile;
    };

    users = mkIf cfg.enableServer {
      users.nix-serve = { group = "nix-serve"; isSystemUser = true; };
      groups.nix-serve = { };
    };

    services.nginx = mkIf cfg.enableServer {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = {
        # ... existing hosts config etc. ...
        "${cfg.host}" = {
          locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
        };
      };
    };
  };
}
