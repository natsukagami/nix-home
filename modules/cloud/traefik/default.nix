{ pkgs, config, lib, ... } :

with lib;
let
  # Copied from traefik.nix
  jsonValue = with types;
    let
      valueType = nullOr (oneOf [
        bool
        int
        float
        str
        (lazyAttrsOf valueType)
        (listOf valueType)
      ]) // {
        description = "JSON value";
        emptyValue.value = { };
      };
    in valueType;

  cfg = config.cloud.traefik;
in
{
  options.cloud.traefik = {
    cloudflareKeyFile = mkOption {
      type = types.path;
      description = "The cloudflake private key file, for Let's Encrypt DNS challenge";
    };

    config = mkOption {
      type = jsonValue;
      default = {};
      description = "The dynamic configuration to be passed to traefik";
    };
  };
  
  config.services.traefik = {
    enable = true;

    staticConfigOptions = {
      # Entrypoints
      # ------------
      ## HTTP entrypoint: always redirect to 443
      entrypoints.http.address = ":80";
      entrypoints.http.http.redirections.entryPoint = {
        to = "https";
        scheme = "https";
      };
      ## HTTPS entrypoint: ok!
      entrypoints.https.address = ":443";
      ## IMAP and SMTP
      entrypoints.imap.address = ":993";
      entrypoints.smtp-submission.address = ":587";

      # Logging
      # -------
      accessLog = {};
      log.level = "info";

      # Dashboard
      # ---------
      api.dashboard = true;

      # ACME Automatic SSL
      # ------------------
      certificatesResolvers.le.acme = {
        email = "natsukagami@gmail.com";
        storage = "/var/lib/traefik/acme.json";
        dnsChallenge.provider = "cloudflare";
        dnsChallenge.delayBeforeCheck = 10;
      };
    };

    dynamicConfigOptions = {};
  };
  # Set up cloudflare key
  config.systemd.services.traefik.environment.CF_DNS_API_TOKEN_FILE = cfg.cloudflareKeyFile;

  # Set up firewall to allow traefik traffic.
  config.networking.firewall.allowedTCPPorts = [ 80 443 993 587 ];
  config.networking.firewall.allowedUDPPorts = [ 443 ]; # QUIC
}
