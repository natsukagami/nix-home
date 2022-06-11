{ config, pkgs, lib, ... }:
let
  cfg = config.nki.programs.kitty;
in
with lib;
{
  programs.kitty = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # set the shell
    settings.shell = "${config.programs.fish.package}/bin/fish";
  };
}
