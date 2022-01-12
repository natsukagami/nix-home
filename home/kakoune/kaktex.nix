{ config, pkgs, lib, ... }:

let
  kaktexScript = ./kaktex;
in
{
  # Create kak-tex executable
  home.file.kaktex = {
    source = kaktexScript;
    executable = true;
    target = ".bin/kaktex";
  };

  # Source kaktex whenever we have a tex file
  programs.my-kakoune.rc = ''
    hook global WinSetOption filetype=(tex|latex) %{
        eval %sh{
          ${kaktexScript} set $kak_client $kak_session
        }
    }
  '';
}
