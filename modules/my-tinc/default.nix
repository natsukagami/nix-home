{ config, pkgs, lib, ... }:

with lib;
let
  hosts = import ./hosts;

  cfg = config.services.my-tinc;

  hostNames = builtins.attrNames hosts;
in
{
  imports = [ ./hosts.nix ];

  options.services.my-tinc = {
    enable = mkEnableOption "my private tinc cloud configuration";
    rsaPrivateKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "./my-key.priv";
      description = "The key file to be used as the private key";
    };
    ed25519PrivateKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "./my-key-ed25519.priv";
      description = "The key file to be used as the private key";
    };
    hostName = mkOption {
      type = types.enum hostNames;
      description = "The configured host name";
    };
    bindPort = mkOption {
      type = types.port;
      default = 655;
      description = "The port to listen on";
    };

    meshIp = mkOption {
      type = types.str;
      description = "The mesh ip to be assigned by hostname";
    };
  };

  config = mkIf cfg.enable (builtins.seq
    (mkIf (isNull cfg.rsaPrivateKey && isNull cfg.ed25519PrivateKey) (builtins.abort "one of the keys must be defined"))
    (
      let
        networkName = "my-tinc";

        myHost = builtins.getAttr cfg.hostName hosts;
        myMeshIp = myHost.subnetAddr;
      in
      {
        services.my-tinc.meshIp = myMeshIp;
        # Scripts that set up the tinc services
        environment.etc = {
          "tinc/${networkName}/tinc-up".source = pkgs.writeScript "tinc-up-${networkName}" ''
            #!${pkgs.stdenv.shell}
            ${pkgs.nettools}/bin/ifconfig $INTERFACE ${myMeshIp} netmask 255.255.255.0
          '';
          "tinc/${networkName}/tinc-down".source = pkgs.writeScript "tinc-down-${networkName}" ''
            #!${pkgs.stdenv.shell}
            /run/wrappers/bin/sudo ${pkgs.nettools}/bin/ifconfig $INTERFACE down
          '';
        };

        # Allow the tinc service to call ifconfig without sudo password.
        security.sudo.extraRules = [
          {
            users = [ "tinc.${networkName}" ];
            commands = [
              {
                command = "${pkgs.nettools}/bin/ifconfig";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        # simple interface setup
        # ----------------------
        networking.interfaces."tinc.${networkName}".ipv4.addresses = [{ address = myMeshIp; prefixLength = 24; }];

        # firewall
        networking.firewall.allowedUDPPorts = [ 655 ];
        networking.firewall.allowedTCPPorts = [ 655 ];

        # configure tinc service
        # ----------------------
        services.tinc.networks."${networkName}" = {

          name = cfg.hostName; # who are we in this network.

          debugLevel = 3; # the debug level for journal -u tinc.private
          chroot = false; # otherwise addresses can't be a DNS
          interfaceType = "tap"; # tun might also work.

          bindToAddress = "* ${toString cfg.bindPort}";

          ed25519PrivateKeyFile = cfg.ed25519PrivateKey;
          rsaPrivateKeyFile = cfg.rsaPrivateKey;

          settings.ExperimentalProtocol = "yes";
        };
      }
    )
  );
}
