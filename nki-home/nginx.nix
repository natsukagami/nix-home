{ lib, config, ... }:
let
  inherit (lib) types;

  cfg = config.nki.nginx;
  tailscaleHost = "kagamipc.dtth.space";
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
    sops.secrets."acme/kagamipc-dtth-space" = { };
    security.acme = {
      acceptTerms = true;
      defaults.email = "nki@nkagami.me";
      certs = {
        "${tailscaleHost}" = {
          domain = "*.${tailscaleHost}";
          group = config.services.nginx.group;
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."acme/kagamipc-dtth-space".path;
        };
      };
    };
    # Nginx HTTPS
    services.nginx = {
      enable = true;
      clientMaxBodySize = "1024M";
      recommendedProxySettings = true;
      defaultListenAddresses = [
        "0.0.0.0"
        "[::0]"
      ];
      virtualHosts = builtins.listToAttrs (
        lib.flatten (
          lib.mapAttrsToList (name: opts: [
            {
              name = "${name}.home.tinc";
              value = {
                forceSSL = true;
                sslCertificate = ./cert.pem;
                sslCertificateKey = config.sops.secrets."nginx/key.pem".path;
              }
              // opts;
            }
            {
              name = "${name}.${tailscaleHost}";
              value = {
                forceSSL = true;
                useACMEHost = "${tailscaleHost}";
              }
              // opts;
            }
          ]) cfg.hosts
        )
      );
    };
    common.linux.tailscale.firewall.allowPorts = [ 443 ];
  };
}
