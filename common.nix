# Common stuff
{ lib, pkgs, config, ... }:
with lib; {
  # swaync disable notifications on screencast
  xdg.portal.wlr.settings.screencast = {
    exec_before = ''which swaync-client && swaync-client --inhibitor-add "xdg-desktop-portal-wlr" || true'';
    exec_after = ''which swaync-client && swaync-client --inhibitor-remove "xdg-desktop-portal-wlr" || true'';
  };
}
