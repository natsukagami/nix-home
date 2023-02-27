{ pkgs, runCommand, zstd, lib, buildFHSUserEnv }:

let
  zotero-tar = builtins.fetchurl {
    url = "https://repo.archlinuxcn.org/aarch64/zotero-6.0.20-1-aarch64.pkg.tar.zst";
    sha256 = "sha256:1fqvcbffqfrnmfz7rcmbngik37wz9dh11q9shrd9cwkq6zay9b6k";
  };

  zotero-src = runCommand "zotero-src" { } ''
    mkdir -p $out
    export PATH=${zstd}/bin:$PATH
    tar xvf ${zotero-tar} -C $out
  '';
in
buildFHSUserEnv {
  name = "zotero";
  targetPkgs = pkgs: with pkgs; [ gtk3 dbus-glib libstartup_notification libpaper ] ++ (with pkgs.xorg; [ libX11 libXt ]);
  runScript = "env QT_SCALE_FACTOR=2 ${zotero-src}/usr/lib/zotero/zotero";
}
