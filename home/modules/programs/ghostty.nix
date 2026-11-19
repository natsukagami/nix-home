{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
in
{
  programs.ghostty = lib.mkMerge [
    # Shared between Linux and macOS
    {
      enable = true;
      settings = {
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

        keybind = [
          "ctrl+shift+n=new_window"
          "ctrl+shift+minus=decrease_font_size:2"
          "ctrl+shift+equal=increase_font_size:2"
        ];

        quit-after-last-window-closed = true;
        quit-after-last-window-closed-delay = "5m";
      };
    }

    (lib.mkIf isLinux {
      settings = {
        theme = "dankcolors";

        background-opacity = "0.85";
        background-blur = true;

        app-notifications = "no-clipboard-copy,no-config-reload";
      };
    })

    (lib.mkIf isDarwin {
      # Ghostty itself is installed outside of Nix: only manage its config.
      package = null;
      settings.macos-option-as-alt = "left";
    })
  ];
}
