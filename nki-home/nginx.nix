{ lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.nki.nginx.hosts = lib.mkOption {
    type = types.attrsOf types.anything;
    default = { };
  };

  config = {
    sops.secrets."nginx/key.pem" = {
      owner = "nginx";
      reloadUnits = [ "nginx.service" ];
    };
    security.dhparams.enable = true;
    security.dhparams.params.nginx.bits = 4096;
    systemd.services.nginx.requires = [ "dhparams-gen-nginx.service" ];
    # Nginx HTTPS
    services.nginx = {
      enable = true;
      clientMaxBodySize = "1024M";
      sslDhparam = true;
      recommendedProxySettings = true;
      defaultListenAddresses = [
        "0.0.0.0"
        "[::0]"
      ];
      virtualHosts = builtins.mapAttrs (
        name: opts:
        {
          serverAliases = [
            "${name}.home.tinc"
            "${name}.kagamipc.dtth.ts"
          ];
          forceSSL = true;
          sslCertificate = ./cert.pem;
          sslCertificateKey = config.sops.secrets."nginx/key.pem".path;
        }
        // opts
      ) config.nki.nginx.hosts;
    };
    common.linux.tailscale.firewall.allowPorts = [ 443 ];
  };
}
