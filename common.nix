let
  # Default shell
  defaultShell = { lib, pkgs, config, ... }: with lib; {
    environment.shells = with pkgs; [ bash fish ];
    users.users = mkMerge [
      { nki.shell = pkgs.fish; }
      # (mkIf (builtins.hasAttr "natsukagami" config.users.users) { natsukagami.shell = pkgs.fish; })
    ];
  };
in
# Common stuff
{ lib, pkgs, config, ... }:
with lib; {
  imports = [ defaultShell ];
  # swaync disable notifications on screencast
  config.xdg.portal.wlr.settings.screencast = {
    exec_before = ''which swaync-client && swaync-client --inhibitor-add "xdg-desktop-portal-wlr" || true'';
    exec_after = ''which swaync-client && swaync-client --inhibitor-remove "xdg-desktop-portal-wlr" || true'';
  };

}
