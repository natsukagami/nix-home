{
  pkgs,
  runCommandLocal,
  zstd,
  lib,
  buildFHSEnvChroot,
}:

let
  zotero-tar = builtins.fetchurl {
    url = "https://repo.archlinuxcn.org/aarch64/zotero-6.0.26-1-aarch64.pkg.tar.zst";
    sha256 = "sha256:0hz9y67bbc9rc6sp8v5i6aa890qvbngpf6hxx2krxrsh3xxn83y2";
  };

  zotero-src = runCommandLocal "zotero-src" { } ''
    mkdir -p $out
    export PATH=${zstd}/bin:$PATH
    tar xvf ${zotero-tar} -C $out
  '';
in
buildFHSEnvChroot {
  name = "zotero";
  targetPkgs =
    pkgs:
    with pkgs;
    [
      gtk3
      dbus-glib
      libstartup_notification
      libpaper
    ]
    ++ (with pkgs.xorg; [
      libX11
      libXt
    ]);
  runScript = "env QT_SCALE_FACTOR=2 ${zotero-src}/usr/lib/zotero/zotero";

  extraInstallCommands = ''
    cp --no-preserve=mode,ownership -r ${zotero-src}/usr/share $out/share
    sed -i "s#/usr/bin/zotero#zotero#g" $out/share/applications/zotero.desktop
  '';
}
