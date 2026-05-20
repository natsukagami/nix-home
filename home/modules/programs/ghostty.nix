{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ghostty.enable = true;
  programs.ghostty.settings = {
    theme = "dankcolors";
    font-family = [
      "Fantasque Sans Mono"
      "Symbols Nerd Font Mono"
      "Font Awesome 7 Free"
      "Font Awesome 6 Free"
      "Font Awesome 5 Free"
      "Noto Color Emoji"
      "monospace"
    ];
    font-size = 16;

    background-opacity = "0.93";
    background-blur = true;

    app-notifications = "no-clipboard-copy,no-config-reload";

    keybind = [
      "ctrl+shift+n=new_window"
      "ctrl+shift+minus=decrease_font_size:2"
      "ctrl+shift+equal=increase_font_size:2"
    ];

    quit-after-last-window-closed = true;
    quit-after-last-window-closed-delay = "5m";
  };
}
