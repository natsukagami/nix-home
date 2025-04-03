{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.services.X11.xfce4-notifyd;
in
{
  options.services.X11.xfce4-notifyd.enable = mkEnableOption "Notification Manager for xfce4";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ xfce.xfce4-notifyd ];
  };
}
