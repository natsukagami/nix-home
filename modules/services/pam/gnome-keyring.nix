{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.nki.services.pam;
in
{
  options.nki.services.pam.enableGnomeKeyring = mkEnableOption "Enable gnome-keyring on login";
  config = mkIf cfg.enableGnomeKeyring {
    security.pam.services.login.enableGnomeKeyring = true;
    security.pam.services.login.gnupg.enable = true;
  };
}
