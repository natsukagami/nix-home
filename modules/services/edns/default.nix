{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.nki.services.edns;
in
{
  options.nki.services.edns = {
    enable = mkEnableOption "Enable encrypted DNS";
    ipv6 = mkEnableOption "Enable ipv6";
    cloaking-rules = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "A set of domain -> ip mapping for cloaking_rules";
    };
  };

  config = mkIf cfg.enable {
    # networking.nameservers = [ "127.0.0.1" "::1" ];
    # networking.resolvconf.enable = mkOverride 1000 false;
    # networking.dhcpcd.extraConfig = "nohook resolv.conf";
    # networking.networkmanager.dns = "none";

    services.dnscrypt-proxy = {
      enable = true;

      settings = {
        server_names = [ ]; # Pick a server yourself

        # Filters
        ipv6_servers = cfg.ipv6;
        require_dnssec = true;
        require_nofilter = true;

        # Sources
        sources.public_resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy/public_resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };

        # Making things go fast
        block_ipv6 = !cfg.ipv6;

        # Anonymized DNS
        anonymized_dns.routes = [
          {
            server_name = "*";
            via = [
              "anon-plan9-dns"
              "anon-v.dnscrypt.up-ipv4"
            ];
          }
        ];
        anonymized_dns.skip_incompatible = true;

        # Cloaking rules
        cloaking_rules = pkgs.writeText "cloaking_rules.txt" (
          lib.strings.concatStringsSep "\n" (
            lib.attrsets.mapAttrsToList (name: ip: "${name} ${ip}") cfg.cloaking-rules
          )
        );
      };
    };
  };
}
