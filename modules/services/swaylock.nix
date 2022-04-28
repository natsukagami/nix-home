{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.swaylock;
in
{
  options.services.swaylock = {
    enable = mkEnableOption "Enable swaylock";
    package = mkOption {
      type = types.package;
      default = pkgs.swaylock;
    };
  };
  config = mkIf cfg.enable {
    security.pam.services.swaylock.text = readFile "${cfg.package}/etc/pam.d/swaylock";
  };
}
