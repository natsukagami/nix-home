{ pkgs, config, lib, ... }:

with lib;
{
  xsession.windowManager.i3.config = mkIf (config.linux.graphical.x11.enablei3) {
    startup = [{ command = "${pkgs.flameshot}/bin/flameshot"; }];
    keybindings = mkOptionDefault { "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui"; };
  };
}
