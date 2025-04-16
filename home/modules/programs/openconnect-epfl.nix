{
  pkgs,
  lib,
  config,
  ...
}:
let
  openconnect-epfl = pkgs.writeShellApplication {
    name = "openconnect-epfl";
    runtimeInputs = with pkgs; [
      openconnect
      rbw
    ];
    text = ''
      RBW_ENTRY="EPFL Microsoft Auth"
      GASPAR_PASSWORD=$(rbw get "$RBW_ENTRY")
      GASPAR_TOKEN=$(rbw code "$RBW_ENTRY")

      printf "%s\n" "$GASPAR_PASSWORD" "$GASPAR_TOKEN" | command sudo openconnect \
          --passwd-on-stdin \
          -u "pham" \
          --useragent='AnyConnect' \
          "https://vpn.epfl.ch"
    '';
  };
in
{
  home.packages = [ openconnect-epfl ];
}
