{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.services.X11.xfce4-notifyd;
in
{
  options.services.X11.xfce4-notifyd.enable = mkEnableOption "Notification Manager for xfce4";

  config = mkIf cfg.enable {
    xdg.configFile."autostart/xfce4-notifyd.desktop" = {
      # Remove the "OnlyShowIn" line
      source = pkgs.runCommand "xfce4-notifyd.desktop"
        {
          buildInput = [ pkgs.gnused ];
          preferLocalBuild = true;
        } ''
        sed "s/OnlyShowIn/# OnlyShowIn/g" \
          < ${pkgs.xfce.xfce4-notifyd}/etc/xdg/autostart/xfce4-notifyd.desktop \
          > $out
      '';
    };
  };
}
