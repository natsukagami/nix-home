let
  localNetworks = { config, lib, pkgs, ... }: with lib; {
    # Default local networks
    options.nki.networking = {
      localNetworks = mkOption {
        type = types.listOf types.str;
        description = "A list of known IPv4 local networks";
      };
      allowLocalPorts = mkOption {
        type = types.listOf types.port;
        default = [ ];
        description = "Open the following ports in all local networks";
      };
    };
    options.nki.networking.ipv6.localNetworks = mkOption {
      type = types.listOf types.str;
      description = "A list of known IPv6 local networks";
    };

    config.nki.networking.localNetworks = [
      "11.0.0.0/24" # tinc
      "100.64.0.0/10" # Headscale
    ];

    config.nki.networking.ipv6.localNetworks = [
      "fd7a:115c:a1e0::/48" # Headscale
    ];

    config.networking = mkIf (config.nki.networking.allowLocalPorts != [ ]) {
      nftables.enable = true;
      firewall.extraInputRules =
        let
          portsStr = concatMapStringsSep ", " toString config.nki.networking.allowLocalPorts;
          ip4Str = concatStringsSep ", " config.nki.networking.localNetworks;
          ip6Str = concatStringsSep ", " config.nki.networking.ipv6.localNetworks;
        in
        ''
          ${if ip4Str == "" then "" else "ip saddr { ${ip4Str} } dport { ${portsStr} } accept"}
          ${if ip6Str == "" then "" else "ip6 saddr { ${ip6Str} } dport { ${portsStr} } accept"}
        '';
    };
  };
in
{ ... }: {
  imports = [ localNetworks ];
}

