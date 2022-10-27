{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.personal.u2f;
in
{
  options.personal.u2f = {
    enable = mkEnableOption "Enable personal U2F login modules and stuff";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pam_u2f # for pamu2fcfg
    ];
    security.pam = mkIf pkgs.stdenv.isLinux {
      u2f = {
        enable = true;
        cue = true;
      };

      # Services
      services.sudo.u2fAuth = true;
      services.login.u2fAuth = true;
      services.swaylock.u2fAuth = mkIf (config.services.swaylock.enable) true;
    };
  };
}
