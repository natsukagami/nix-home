{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.programs.fish.tide.nix-shell;
in
{
  options.programs.fish.tide.nix-shell = {
    enable = mkEnableOption "An indicator of having a `nix shell` environment";
  };

  config.programs.fish = mkIf cfg.enable {
    functions._tide_item_nix_shell = ''
      if string match -q "/nix/store/*" $PATH
        set -U tide_nix_shell_color blue
        set -U tide_nix_shell_bg_color normal
        _tide_print_item nix_shell "❄"
      end
    '';
  };
}
