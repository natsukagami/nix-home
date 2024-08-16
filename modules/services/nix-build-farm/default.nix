{ config, lib, ... }:
with { inherit (lib) mkOption types mkIf; };
let
  cfg = config.services.nix-build-farm;
  hosts = import ./hosts.nix;

  build-user = "nix-builder";

  isBuilder = host: host ? "builder";
  allBuilders = lib.filterAttrs (_: isBuilder) hosts;
in
{
  options.services.nix-build-farm = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable nix-build-farm as a client";
    };
    hostname = mkOption {
      type = types.enum (builtins.attrNames hosts);
      description = "The hostname as listed in ./hosts.nix file";
    };
    privateKeyFile = mkOption {
      type = types.path;
      description = "The path to the private SSH key file";
    };
  };

  config = mkIf cfg.enable (
    let
      host = hosts.${cfg.hostname};
      otherHosts = lib.filterAttrs (name: _: name != cfg.hostname) hosts;
      otherBuilders = lib.filterAttrs (name: _: name != cfg.hostname) allBuilders;
    in
    {
      nix.distributedBuilds = true;
      nix.buildMachines = lib.mapAttrsToList
        (name: host: {
          hostName = host.host;
          sshUser = build-user;
        } // host.builder)
        otherBuilders;

      programs.ssh.extraConfig = (lib.concatStringsSep "\n" (lib.mapAttrsToList
        (name: host: ''
          Host ${name}
            HostName ${host.host}
            User ${build-user}
            IdentitiesOnly yes
            IdentityFile ${cfg.privateKeyFile}
        '')
        otherBuilders));

      users = mkIf (isBuilder host) {
        users.${build-user} = {
          description = "Nix build farm user";
          group = build-user;
          isNormalUser = true;
          openssh.authorizedKeys.keys = lib.mapAttrsToList (_: host: host.pubKey) otherHosts;
        };
        groups.${build-user} = { };
      };
    }
  );
}


