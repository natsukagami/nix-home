# A monitor list and common sway set up
{ config, pkgs, lib, ... }: with lib;
let
  monitors = {
    # Internal
    "framework" = {
      name = "BOE 0x0BCA Unknown";
      meta.mode = { width = 2256; height = 1504; refresh = 60.0; };
      scale = 1.25;
    };
    # External
    ## Work @ EPFL
    "work" = {
      name = "LG Electronics LG ULTRAFINE 301MAXSGHD10";
      meta.mode = { width = 3840; height = 2160; refresh = 60.0; };
      scale = 1.25;
    };
    "home_4k" = {
      name = "AOC U28G2G6B PPYP2JA000013";
      scale = 1.5;
      adaptive_sync = "on";
      meta = {
        connection = "DP-2";
        mode = { width = 3840; height = 2160; refresh = 60.0; };
        fixedPosition = { x = 0; y = 0; };
        niriName = "PNP(AOC) U28G2G6B PPYP2JA000013";
      };
    };
    "home_1440" = {
      name = "AOC Q27G2G3R3B VXJP6HA000442";
      adaptive_sync = "on";
      meta = {
        connection = "DP-3";
        mode = { width = 2560; height = 1440; refresh = 165.0; };
        fixedPosition = { x = 2560; y = 0; };
        niriName = "PNP(AOC) Q27G2G3R3B VXJP6HA000442";
      };
    };

    "viewsonic_1080" = {
      name = "ViewSonic Corporation XG2402 SERIES V4K182501054";
      meta.mode = { width = 1920; height = 1080; refresh = 144.0; };
      adaptive_sync = "on";
    };

  };

  eachMonitor = _name: monitor: {
    name = monitor.name;
    value = builtins.removeAttrs monitor [ "scale" "name" "meta" ] // (lib.optionalAttrs (monitor ? scale) {
      scale = toString monitor.scale;
    }) // {
      mode = with monitor.meta.mode; "${toString width}x${toString height}@${toString refresh}Hz";
    } // (lib.optionalAttrs (monitor.meta ? fixedPosition) {
      position = with monitor.meta.fixedPosition; "${toString x} ${toString y}";
    });
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

