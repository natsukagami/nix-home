{ config, pkgs, lib, ... }:

{
  # Source kaktex whenever we have a tex file
  programs.my-kakoune.rc = ''
    hook global WinSetOption filetype=(tex|latex) %{
      hook window WinDisplay '.*' %{
        eval %sh{
          ${./kaktex} set $kak_client $kak_session
        }
      }
    }
  '';
}
