{ pkgs, config, lib, ... }:

with lib;
{
  imports = [ ./packages.nix ../modules/X11/xfce4-notifyd.nix ];

  home.sessionVariables = {
    # Set up Java font style
    _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";
  };

  # X Session settings
  xsession.enable = true;

  # Wallpaper
  home.file.wallpaper = {
    source = ./. + "/wallpaper.jpg";
    target = "wallpaper.jpg";
  };

  # Cursor
  xsession.pointerCursor = {
    package = pkgs.numix-cursor-theme;
    name = "Numix-Cursor-Light";
    size = 32;
  };

  # MIME set ups
  xdg.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
    "x-scheme-handler/ftp" = [ "firefox.desktop" ];
    "x-scheme-handler/ftps" = [ "firefox.desktop" ];
    "x-scheme-handler/mailspring" = [ "Mailspring.desktop" ];
  };

  # Mimic the clipboard stuff in MacOS
  home.packages = [
    (pkgs.writeShellScriptBin "pbcopy" ''
      exec ${pkgs.xsel}/bin/xsel -ib
    '')
    (pkgs.writeShellScriptBin "pbpaste" ''
      exec ${pkgs.xsel}/bin/xsel -ob
    '')
  ];

  # Notification system
  services.X11.xfce4-notifyd.enable = true;

  # IBus configuration
  dconf.settings."desktop/ibus/general" = {
    engines-order = hm.gvariant.mkArray hm.gvariant.type.string [ "xkb:jp::jpn" "mozc-jp" "Bamboo" ];
    reload-engines = hm.gvariant.mkArray hm.gvariant.type.string [ "xkb:jp::jpn" "mozc-jp" "Bamboo" ];
  };
  dconf.settings."desktop/ibus/general/hotkey" = {
    triggers = hm.gvariant.mkArray hm.gvariant.type.string [ "<Super>z" ];
  };
}
