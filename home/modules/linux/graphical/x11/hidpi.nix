{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.linux.graphical.x11;
in
{
  options.linux.graphical.x11.hidpi = mkEnableOption "Enable hiDPI mode for X11";

  config = mkIf cfg.hidpi {
    # X resources for 4k monitor
    home.file."4k.Xresources" = {
      target = ".config/X11/.Xresources";
      text = ''
        Xft.dpi: 192
        ! These might also be useful depending on your monitor and personal preference:
        Xft.autohint: 0
        Xft.lcdfilter:  lcddefault
        Xft.hintstyle:  hintfull
        Xft.hinting: 1
        Xft.antialias: 1
        Xft.rgba: rgb
      '';
    };
    # Load 4k Xresources
    xsession.initExtra = ''
      xrdb -merge ~/.config/X11/.Xresources
      feh --bg-fill ~/wallpaper.jpg
    '';
  };
}
