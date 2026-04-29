{ pkgs, lib, ... }:

let
  osu-script-inner = pkgs.writeShellScript "osu-script-inner" ''
    test -n "$PIPEWIRE_ALSA" || export PIPEWIRE_ALSA='{ application.process.id='"$$"' alsa.channels=2 alsa.rate=96000 alsa.buffer-bytes=2048 alsa.period-bytes=128 }'
    test -n "$PIPEWIRE_LATENCY" || export PIPEWIRE_LATENCY='1/96000'
    export SDL_VIDEODRIVER=wayland
    export SDL_VIDEO_DOUBLE_BUFFER=1
    export OSU_SDL3=1

    exec "$@"
  '';
  osu-script = pkgs.writeShellScript "osu-script" ''
    exec gamemoderun chrt -r 70 ${osu-script-inner} osu!
  '';
  osu-pkg =
    with pkgs;
    with lib;
    appimageTools.wrapType2 rec {
      pname = "osu-lazer-bin";
      version = "2026.428.0-tachyon";
      src = fetchurl {
        url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
        hash = "sha256-egZkBQYu0eOZwRbMsQ6oBgpC20nzQ4t0SChKK9B7U7A=";
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
