{ pkgs, runCommand, zstd, lib, buildFHSUserEnv }:

let
  typora-tar = builtins.fetchurl {
    url = "https://download.typora.io/linux/Typora-linux-arm64.tar.gz";
    sha256 = "sha256:1xp25rvr8hr8b4dwb55d9229bbnpq7kd2bxvz7l3dfhn39zpxxjg";
  };

  typora-src = runCommand "typora-src" { } ''
    mkdir -p $out
    tar xvf ${typora-tar} -C $out
  '';
in
buildFHSUserEnv {
  name = "typora";
  targetPkgs = pkgs: with pkgs; [
    glib
    nss
    nspr
    at-spi2-atk
    cups
    dbus
    gtk3
    pango
    cairo
    mesa
    expat
    libdrm
    libxkbcommon
    alsa-lib
    freefont_ttf
    liberation_ttf
    wayland
    libglvnd
    electron
  ] ++ (with pkgs.xorg; [
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
  ]);
  extraBuildCommands = ''
    # ldd ${typora-src}/bin/Typora-linux-arm64/Typora && false
  '';
  # runScript = "${typora-src}/bin/Typora-linux-arm64/Typora --enable-features=UseOzonePlatform --ozone-platform=wayland";
  runScript = "electron ${typora-src}/bin/Typora-linux-arm64/resources/app.asar";
}
