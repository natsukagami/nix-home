# A monitor list and common sway set up
{ config, pkgs, lib, ... }: with lib;
let
  monitors = {
    # Internal
    "framework" = {
      name = "BOE 0x0BCA Unknown";
      mode = "2256x1504@60Hz";
      scale = 1.25;
    };
    # External
    ## Work @ EPFL
    "work" = {
      name = "LG Electronics LG ULTRAFINE 301MAXSGHD10";
      mode = "3840x2160@60Hz";
      scale = 1.25;
    };
    "home_4k" = {
      name = "AOC U28G2G6B PPYP2JA000013";
      mode = "3840x2160@60Hz";
      scale = 1.5;
      adaptive_sync = "on";
      # render_bit_depth = "10";
    };
    "home_1440" = {
      name = "AOC Q27G2G3R3B VXJP6HA000442";
      mode = "2560x1440@165Hz";
      adaptive_sync = "on";
    };

    "viewsonic_1080" = {
      name = "ViewSonic Corporation XG2402 SERIES V4K182501054";
      mode = "1920x1080@144Hz";
      adaptive_sync = "on";
    };

  };

  eachMonitor = _name: monitor: {
    name = monitor.name;
    value = builtins.removeAttrs monitor [ "scale" "name" ] // (if monitor ? scale then {
      scale = toString monitor.scale;
    } else { });
  };
in
{
  options.common.monitors = mkOption {
    type = types.attrsOf types.attrs;
    description = "A list of monitors";
  };
  config.common.monitors = monitors;
  config.home.packages = mkIf config.wayland.windowManager.sway.enable (with pkgs; [ kanshi ]);
  config.wayland.windowManager.sway.config.output = mkIf config.wayland.windowManager.sway.enable (
    mapAttrs' eachMonitor config.common.monitors
  );
}

