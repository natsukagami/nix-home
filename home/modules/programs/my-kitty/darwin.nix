{ pkgs, config, lib, ... }:
let
  cfg = config.nki.programs.kitty;
  cmd = "cmd";
in
with lib; {
  programs.kitty = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {

    # Darwin-specific setup
    darwinLaunchOptions = [
      "--single-instance"
      "--start-as=fullscreen"
    ];

    # Tabs and layouts keybindings
    keybindings = {
      # Backslash
      "0x5d" = "send_text all \\u005c";

      "${cmd}+shift+o" = "launch --location=vsplit";
      "${cmd}+o" = "launch --location=hsplit";
      "${cmd}+shift+r" = "layout_action rotate";
      ## Move the active window in the indicated direction
      "${cmd}+shift+h" = "move_window left";
      "${cmd}+shift+j" = "move_window up";
      "${cmd}+shift+k" = "move_window down";
      "${cmd}+shift+l" = "move_window right";
      ## Switch focus to the neighboring window in the indicated direction
      "${cmd}+h" = "neighboring_window left";
      "${cmd}+j" = "neighboring_window up";
      "${cmd}+k" = "neighboring_window down ";
      "${cmd}+l" = "neighboring_window right";
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

      # Layouts
      ## Mouse focus
      focus_follows_mouse = true;
      ## Layout options
      # Layouts
      enabled_layouts = "Splits";
      inactive_text_alpha = "0.65";

      # MacOS specific
      macos_option_as_alt = "left";
    };
  };
}

