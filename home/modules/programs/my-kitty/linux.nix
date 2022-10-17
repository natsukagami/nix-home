{ config, pkgs, lib, ... }:
let
  cfg = config.nki.programs.kitty;
in
with lib;
{
  programs.kitty = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # set the shell
    settings.shell = "${config.programs.fish.package}/bin/fish";

    keybindings = {
      "0xa5" = "send_text all \\u005c";
      "ctrl+shift+n" = "new_os_window_with_cwd";
      "ctrl+shift+enter" = "new_window_with_cwd";
    };
  };
}
