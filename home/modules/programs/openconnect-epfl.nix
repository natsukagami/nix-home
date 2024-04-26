{ pkgs, lib, config, ... }:
let
  openconnect-epfl = pkgs.writeShellApplication {
    name = "openconnect-epfl";
    runtimeInputs = with pkgs; [ openconnect rbw ];
    text = ''
      GASPAR_PASSWORD=$(rbw get gaspar)
      GASPAR_TOKEN=$(rbw code gaspar)

      printf "%s\n%s\n" "$GASPAR_PASSWORD" "$GASPAR_TOKEN" | sudo openconnect \
          --passwd-on-stdin \
          -u pham \
           --useragent='AnyConnect' \
          "https://vpn.epfl.ch"
    '';
  };
in
{
  home.packages = [ openconnect-epfl ];
}

