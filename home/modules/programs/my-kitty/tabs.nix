{ config, pkgs, lib, ... }:

let
  cfg = config.programs.my-kitty;
  cmd = cfg.cmd;
in
with lib;
{
  programs.kitty.keybindings = mkIf cfg.enableTabs {
    "${cmd}+t" = "new_tab_with_cwd";
    "${cmd}+shift+t" = "new_tab";
    "${cmd}+shift+o" = "launch --cwd=current --location=vsplit";
    "${cmd}+o" = "launch --cwd=current --location=hsplit";
    "${cmd}+shift+r" = "layout_action rotate";
    ## Move the active window in the indicated direction
    "${cmd}+shift+h" = "move_window left";
    "${cmd}+shift+k" = "move_window up";
    "${cmd}+shift+j" = "move_window down";
    "${cmd}+shift+l" = "move_window right";
    ## Switch focus to the neighboring window in the indicated direction
    "${cmd}+h" = "neighboring_window left";
    "${cmd}+k" = "neighboring_window up";
    "${cmd}+j" = "neighboring_window down ";
    "${cmd}+l" = "neighboring_window right";
    ## Detach window to its own tab
    "${cmd}+d" = "detach_window new-tab";
    ## Change layout to fullscreen (stack) and back
    "${cmd}+f" = "toggle_layout stack";
  };
}
