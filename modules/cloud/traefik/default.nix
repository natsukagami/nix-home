{ pkgs, config, lib, ... }:

with lib;
let
  # Copied from traefik.nix
  jsonValue = with types;
    let
      valueType = nullOr
        (oneOf [
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
    in
    valueType;

  # https://www.cloudflare.com/ips/
  trustedIPs =
    let
      files = [
        (pkgs.fetchurl {
          url = "https://www.cloudflare.com/ips-v4";
          hash = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
        })
        (pkgs.fetchurl {
          url = "https://www.cloudflare.com/ips-v6";
          hash = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
        })
      ];

      readLines = path: lib.splitString "\n" (builtins.readFile path);
    in
    lib.concatMap readLines files;

  cfg = config.cloud.traefik;
in
{
  imports = [ ./config.nix ./dashboard.nix ./certs-dumper.nix ];
  options.cloud.traefik = {
    cloudflareKeyFile = mkOption {
      type = types.path;
      description = "The cloudflake private key file, for Let's Encrypt DNS challenge";
    };

    config = mkOption {
      type = jsonValue;
      default = { };
      description = "The dynamic configuration to be passed to traefik";
    };

    certsPath = mkOption {
      type = types.str;
      default = "/var/lib/traefik/acme.json";
      description = "The location to read and write the certificates file onto";
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
      entrypoints.https.forwardedHeaders.trustedIPs = trustedIPs;
      ## IMAP and SMTP
      entrypoints.imap.address = ":993";
      entrypoints.smtp-submission.address = ":587";
      entrypoints.smtp-submission-ssl.address = ":465";
      ## Wireguard
      entrypoints.wireguard.address = ":51820/udp";

      # Logging
      # -------
      accessLog = { };
      log.level = "info";

      # ACME Automatic SSL
      # ------------------
      certificatesResolvers.le.acme = {
        email = "natsukagami@gmail.com";
        storage = cfg.certsPath;
        dnsChallenge.provider = "cloudflare";
        dnsChallenge.delayBeforeCheck = 10;
      };
    };

    dynamicConfigOptions = cfg.config;
  };
  # Set up cloudflare key
  config.systemd.services.traefik.environment.CF_DNS_API_TOKEN_FILE = cfg.cloudflareKeyFile;

  # Set up firewall to allow traefik traffic.
  config.networking.firewall.allowedTCPPorts = [ 443 993 587 465 ];
  config.networking.firewall.allowedUDPPorts = [
    443 # QUIC
    51820 # Wireguard
  ];
}
