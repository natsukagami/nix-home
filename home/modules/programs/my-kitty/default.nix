{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.nki.programs.kitty;

  theme =
    {
      lib,
      options,
      config,
      ...
    }:
    {
      programs.kitty = lib.mkIf config.nki.programs.kitty.enable (
        if builtins.hasAttr "themeFile" options.programs.kitty then
          {
            themeFile = "ayu_light";
          }
        else
          {
            theme = "Ayu Light";
          }
      );
    };
in
with lib;
{
  imports = [
    theme
    ./darwin.nix
    ./linux.nix
    ./tabs.nix
  ];

  options.nki.programs.kitty = {
    enable = mkEnableOption "Enable kitty";
    setDefault = mkOption {
      type = types.bool;
      description = "Set kitty as default terminal";
      default = true;
    };

    package = mkOption {
      type = types.package;
      default = pkgs.kitty;
    };

    # font
    fontSize = mkOption {
      type = types.int;
      description = "Font size";
      default = 21;
    };

    background = mkOption {
      type = types.nullOr types.path;
      description = "Path to the background image. If not set, default to a 0.9 opacity";
      default = null;
    };

    cmd = mkOption {
      type = types.str;
      description = "The main control key";
      default = if pkgs.stdenv.isDarwin then "cmd" else "ctrl";
    };

    enableTabs = mkOption {
      type = types.bool;
      description = "Enable tabs";
      default = pkgs.stdenv.isDarwin;
    };
  };

  config = mkIf cfg.enable {
    linux.graphical = mkIf cfg.setDefault {
      defaults.terminal.package = cfg.package;
    };
    programs.kitty = {
      enable = true;

      package = cfg.package;

      font.package = pkgs.fantasque-sans-mono;
      font.name = "Fantasque Sans Mono";
      font.size = cfg.fontSize;

      settings =
        let
          # Background color and transparency
          background =
            if isNull cfg.background then
              {
                background_opacity = "0.93";
                dynamic_background_opacity = true;
              }
            else
              {
                background_image = "${cfg.background}";
                background_image_layout = "scaled";
                background_tint = "0.85";
              };
        in
        mkMerge [
          background
          {
            # Scrollback (128MBs)
            scrollback_pager_history_size = 128;

            # Disable Shell integration (leave it for Nix)
            shell_integration = "no-rc";

            # Allow remote control (for kakoune integration)
            allow_remote_control = true;

            # Mouse focus
            focus_follows_mouse = true;
          }
        ];

      keybindings = {
        "${cfg.cmd}+shift+equal" = "no_op"; # Not possible with a JIS keyboard
        "${cfg.cmd}+shift+^" = "change_font_size all +2.0"; # ... so use ^ instead

        ## Clear screen
        "${cfg.cmd}+backspace" = "clear_terminal to_cursor active";
        "${cfg.cmd}+shift+backspace" = "clear_terminal reset active";

        ## Command scrolling
        "${cfg.cmd}+shift+j" = "scroll_to_prompt 1";
        "${cfg.cmd}+shift+k" = "scroll_to_prompt -1";
      };

      extraConfig =
        let
          # Nerd Fonts glyph map
          glyphMap = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/Sharparam/dotfiles/main/kitty/.config/kitty/font-nerd-symbols.conf";
            hash = "sha256-1OaDWLC3y8ASD2ttRWWgPEpRnfKXu6H6vS3cFVpzT0o=";
          };
        in
        ''
          include ${glyphMap}
        '';
    };

    # Open protocol
    xdg.configFile."kitty/open-actions.conf".text = ''
      protocol file
      fragment_matches [0-9]+
      action launch --type=overlay --cwd=current -- $\{EDITOR} +$\{FRAGMENT} -- $\{FILE_PATH}

      # Open HTML files with xdg-open
      protocol file
      mime text/html
      action launch xdg-open $\{FILE_PATH}

      # Open text files without fragments in the editor
      protocol file
      mime text/*
      action launch --type=overlay --cwd=current -- $\{EDITOR} -- $\{FILE_PATH}

      # Open other files with xdg-open
      protocol file
      action launch xdg-open $\{FILE_PATH}
    '';

    programs.fish.shellAliases = {
      "ssh+" = "kitten ssh";
      "clip" = "kitten clipboard";
      "eg" = "kitten hyperlinked-grep";
      "icat" = "kitten icat";
      "notify" = "kitten notify";
    };
  };
}
