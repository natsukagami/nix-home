{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nki.programs.discord;
in
{
  options.nki.programs.discord = {
    enable = mkEnableOption "Enable discord";

    basePackage = mkOption {
      type = types.package;
      default = pkgs.discord;
      description = "The base Discord package that will get patched";
    };

    package = mkOption {
      type = types.package;
      default = cfg.basePackage.override { nss = pkgs.nss_latest; };
      description = "The actual package to use";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
