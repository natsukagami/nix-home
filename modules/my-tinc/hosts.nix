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
      addresses = [ { address = host.address; } ];
      subnets = [ { address = host.subnetAddr; } ];
      rsaPublicKey = if (host ? "rsaPublicKey") then (builtins.readFile host.rsaPublicKey) else null;
      settings.Ed25519PublicKey = mkIf (host ? "ed25519PublicKey") (builtins.readFile host.ed25519PublicKey);
    }) hosts;
  };
}
