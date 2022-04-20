{ pkgs, config, lib, ... }:
with lib;
{
  imports = [ ./x11/hidpi.nix ./x11/i3.nix ];
  config = mkIf (config.linux.graphical.type == "x11") {
    # X Session settings
    xsession.enable = true;

    # Additional packages
    home.packages = with pkgs; [
      xsel # Clipboard management

      # Mimic the clipboard stuff in MacOS
      (pkgs.writeShellScriptBin "pbcopy" ''
        exec ${pkgs.xsel}/bin/xsel -ib
      '')
      (pkgs.writeShellScriptBin "pbpaste" ''
        exec ${pkgs.xsel}/bin/xsel -ob
      '')
    ];

    # Notification system
    services.X11.xfce4-notifyd.enable = true;

    # Picom: X Compositor
    services.picom = {
      enable = true;
      blur = true;
      fade = true;
      fadeDelta = 3;
      shadow = true;
    };
  };
}

