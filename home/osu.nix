{ pkgs, lib, ... }:

let
  # osu-pkg = pkgs.unstable.osu-lazer-bin;
  osu-pkg = with pkgs; with lib;
    appimageTools.wrapType2 rec {
      pname = "osu-lazer-bin";
      version = "2024.302.1";
      src = pkgs.fetchurl {
        url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
        hash = "sha256-vYG3viY9GBtgaY8ThCSWss+zzjAyVa4fmrWrQdYcUow=";
      };

      extraPkgs = pkgs: with pkgs; [ icu ];

      extraInstallCommands =
        let contents = appimageTools.extract { inherit pname version src; };
        in
        ''
          mv -v $out/bin/${pname}-${version} $out/bin/osu\!
          install -m 444 -D ${contents}/osu\!.desktop -t $out/share/applications
          for i in 16 32 48 64 96 128 256 512 1024; do
            install -D ${contents}/osu\!.png $out/share/icons/hicolor/''${i}x$i/apps/osu\!.png
          done
        '';
    };

  osu-wrapper = pkgs.writeScriptBin "osu!" ''
    export COMPlus_GCGen0MaxBudget="600000"
    export PIPEWIRE_LATENCY="32/48000"
    export vblank_mode="0"
    ${osu-pkg}/bin/osu\!
  '';
in
{
  home.packages = [ osu-wrapper ];
  # home.packages = [ pkgs.osu-lazer ];
}

