{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.linux.graphical.alacritty;
in
{
  options.linux.graphical.alacritty = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.alacritty;
    };
  };
  config.programs.alacritty = mkIf (config.linux.graphical.type != null && cfg.enable) {
    enable = true;
    package = cfg.package;

    settings = {
      window.opacity = mkIf (strings.hasPrefix "0.10" cfg.package.version) 0.9;
      background_opacity = mkIf (strings.hasPrefix "0.9" cfg.package.version) 0.9;
      font = {
        size = 14.0;
        normal.family = "Fantasque Sans Mono Nerd Font";
      };
      shell = {
        program = "/bin/sh";
        args = [
          "-ic"
          "${config.programs.fish.package}/bin/fish"
        ];
      };
      colors = {
        # Default colors
        primary.background = "0xf1f1f1";
        primary.foreground = "0x424242";

        # Normal colors
        normal.black = "0x212121";
        normal.red = "0xc30771";
        normal.green = "0x10a778";
        normal.yellow = "0xa89c14";
        normal.blue = "0x008ec4";
        normal.magenta = "0x523c79";
        normal.cyan = "0x20a5ba";
        normal.white = "0xe0e0e0";

        # Bright colors
        bright.black = "0x212121";
        bright.red = "0xfb007a";
        bright.green = "0x5fd7af";
        bright.yellow = "0xf3e430";
        bright.blue = "0x20bbfc";
        bright.magenta = "0x6855de";
        bright.cyan = "0x4fb8cc";
        bright.white = "0xf1f1f1";
      };

      key_bindings = [
        {
          key = "C";
          mods = "Alt|Control";
          action = "SpawnNewInstance";
        }
      ];
    };
  };
}
