{
  fish,
  lib,
  writeScript,
  writeTextDir,
  kakouneUtils,
  ...
}:
let
  kaktex-script = writeScript "kaktex" ''
    #!/usr/bin/env ${lib.getExe fish}

    ${builtins.readFile ./kaktex.fish}
  '';
  kaktex = writeTextDir "kaktex.kak" ''
    hook global WinSetOption filetype=(tex|latex) %{
      hook window WinDisplay '.*' %{
        eval %sh{
          ${kaktex-script} set $kak_client $kak_session
        }
      }
    }
  '';
in
kakouneUtils.buildKakounePluginFrom2Nix {
  pname = "kaktex";
  version = "latest";
  src = kaktex;
}
