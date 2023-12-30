{ pkgs, config, lib, ... }:

let
  osu-pkg = pkgs.unstable.osu-lazer-bin;
  # pkgs.unstable.osu-lazer-bin.overrideAttrs (attrs: rec {
  #   version = "2023.1130.0";
  #   src = pkgs.fetchurl {
  #     url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
  #     hash = "sha256-dQuyKjCZaIl3uaI81qRMt5NzBxfmyROVbJrVAqzuZxg=";
  #   };
  # });
  # with pkgs; with lib;
  # appimageTools.wrapType2 rec {
  #   pname = "osu-lazer-bin";
  #   version = "2023.1130.0";
  #   src = pkgs.fetchurl {
  #     url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
  #     hash = "sha256-dQuyKjCZaIl3uaI81qRMt5NzBxfmyROVbJrVAqzuZxg=";
  #   };

  #   extraPkgs = pkgs: with pkgs; [ icu ];

  #   extraInstallCommands =
  #     let contents = appimageTools.extract { inherit pname version src; };
  #     in
  #     ''
  #       mv -v $out/bin/${pname}-${version} $out/bin/osu\!
  #       install -m 444 -D ${contents}/osu\!.desktop -t $out/share/applications
  #       for i in 16 32 48 64 96 128 256 512 1024; do
  #         install -D ${contents}/osu\!.png $out/share/icons/hicolor/''${i}x$i/apps/osu\!.png
  #       done
  #     '';
  # };
in
{
  home.packages = [ osu-pkg ];
  # home.packages = [ pkgs.osu-lazer ];
}
