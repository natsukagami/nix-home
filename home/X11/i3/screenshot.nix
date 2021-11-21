{ pkgs, config, lib, ... }:

with lib;
{
  xsession.windowManager.i3.config = {
    startup = [ { command = "${pkgs.flameshot}/bin/flameshot"; } ];
    keybindings = mkOptionDefault { "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui"; };
  };
}
