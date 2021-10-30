{ config, pkgs, lib, ... }:

with lib;
let
  hosts = import ./hosts;

  cfg = config.services.my-tinc;

  mapAttrs = f: attrs: builtins.listToAttrs (
    map (name: { inherit name; value = f name (builtins.getAttr name attrs); }) (builtins.attrNames attrs)
  );
in
{
  config = mkIf cfg.enable {
    # All hosts we know of
    services.tinc.networks.my-tinc.hostSettings = mapAttrs (name: host: {
      addresses = if (host ? address) then [ { address = host.address; } ] else [];
      subnets = [ { address = host.subnetAddr; } ];
      rsaPublicKey = mkIf (host ? "rsaPublicKey") host.rsaPublicKey;
      settings.Ed25519PublicKey = mkIf (host ? "ed25519PublicKey") host.ed25519PublicKey;
    }) hosts;
  };
}
