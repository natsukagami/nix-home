{ config, pkgs, lib, ... }:

let
  cfg = config.nki.programs.kitty;
  cmd = cfg.cmd;
in
with lib;
{
  programs.kitty = mkIf cfg.enableTabs {
    keybindings = {
      "${cmd}+t" = "new_tab_with_cwd";
      "${cmd}+shift+t" = "new_tab";
      "${cmd}+shift+o" = "launch --cwd=current --location=vsplit";
      "${cmd}+o" = "launch --cwd=current --location=hsplit";
      "${cmd}+r" = "start_resizing_window";
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
      "${cmd}+shift+d" = "detach_window new-tab";
      ## Change layout to fullscreen (stack) and back
      "${cmd}+f" = "toggle_layout stack";
    }
    # Tab bindings
    // builtins.listToAttrs
      (map
        (x: attrsets.nameValuePair "${cmd}+${toString x}" "goto_tab ${toString x}")
        (lists.range 1 9));
    settings = {
      # Tab settings
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.lightgreen}{fmt.bold}[{index}]{fmt.nobold} {fmt.fg.tab}{title}";
      active_tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}";
      tab_bar_background = "#555";
      active_tab_font_style = "normal";

      ## Layout options
      # Layouts
      enabled_layouts = "splits,stack";
      inactive_text_alpha = "0.65";
    };
  };
}
