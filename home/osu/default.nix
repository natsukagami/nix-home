{ pkgs, lib, ... }:

let
  osu-script = pkgs.writeShellScript "osu-script" ''
    export PIPEWIRE_ALSA='{ application.process.id='"$$"'  alsa.buffer-bytes='4096' alsa.period-bytes='64' }'
    export SDL_VIDEODRIVER=wayland
    export SDL_VIDEO_DOUBLE_BUFFER=1
    export OSU_SDL3=1

    exec osu! "$@"
  '';
  # osu-pkg = pkgs.unstable.osu-lazer-bin;
  osu-pkg =
    with pkgs;
    with lib;
    appimageTools.wrapType2 rec {
      pname = "osu-lazer-bin";
      version = "2026.124.0-tachyon";
      src = fetchurl {
        url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
        hash = "sha256-v7VUcA37JRpfhHSQUI5DD+Sl/0QGJk/4hKkvZOuGWgM=";
        # hash = lib.fakeHash;
      };
      extraPkgs = pkgs: with pkgs; [ icu ];

      extraInstallCommands =
        let
          contents = appimageTools.extract { inherit pname version src; };
        in
        ''
          sed "s#osu!#$out/bin/${pname}#g" ${osu-script} > $out/bin/osu!
          chmod +x $out/bin/osu!
          install -m 444 -D ${contents}/osu\!.desktop -t $out/share/applications
          install -m 444 -D ${./mimetypes.xml} $out/share/mime/packages/${pname}.xml
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
