{ pkgs, lib, ... }:

let
  # osu-pkg = pkgs.unstable.osu-lazer-bin;
  osu-pkg = with pkgs; with lib;
    appimageTools.wrapType2 rec {
      pname = "osu-lazer-bin";
      version = "2024.1219.2";
      src = fetchurl {
        url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
        hash = "sha256-gRUr7jf0+Xbfz8FurPk/o7F67TYisdNySNzVWEMb1es=";
      };
      extraPkgs = pkgs: with pkgs; [ icu ];

      extraInstallCommands =
        let contents = appimageTools.extract { inherit pname version src; };
        in
        ''
          mv -v $out/bin/${pname} $out/bin/osu\!
          install -m 444 -D ${contents}/osu\!.desktop -t $out/share/applications
          for i in 16 32 48 64 96 128 256 512 1024; do
            install -D ${contents}/osu.png $out/share/icons/hicolor/''${i}x$i/apps/osu.png
          done
        '';
    };
in
{
  home.packages = [ osu-pkg ];
  xdg.mimeApps.defaultApplications."x-scheme-handler/osu" = "osu!.desktop";
  # home.packages = [ pkgs.osu-lazer ];
}

