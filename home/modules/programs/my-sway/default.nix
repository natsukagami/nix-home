{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.programs.my-sway;

  mod = "Mod4";
  # List of workspaces
  workspaces = [
    "1: web"
    "2: chat"
    "3: code"
    "4: music"
    "5: extra"
    "6: 6"
    "7: 7"
    "8: 8"
    "9: 9"
    "10: 10"
  ];
  wsAttrs = builtins.listToAttrs (
    map
      (i: { name = toString (remainder i 10); value = builtins.elemAt workspaces (i - 1); })
      (range 1 11)
  );
  remainder = x: y: x - (builtins.div x y) * y;
  range = from: to:
    let
      f = cur: if cur == to then [ ] else [ cur ] ++ f (cur + 1);
    in
    f from;

in
{
  imports = [ ./ibus.nix ];

  options.programs.my-sway = {
    enable = mkEnableOption "Enable the sway configuration";
    fontSize = mkOption {
      type = types.float;
      description = "The default font size";
    };
    enableTouchpad = mkOption {
      type = types.bool;
      description = "Whether to enable the touchpad";
      default = true;
    };
    wallpaper = mkOption {
      type = types.oneOf [ types.path types.str ];
      description = "Path to the wallpaper to be used";
      default = "";
    };
    terminal = mkOption {
      type = types.str;
      description = "The command to the terminal emulator to be used";
      default = "${pkgs.alacritty}/bin/alacritty";
    };

    enableLaptopBars = mkOption {
      type = types.bool;
      description = "Whether to enable laptop-specific bars (battery)";
      default = true;
    };
  };

  config.wayland.windowManager.sway = mkIf cfg.enable {
    enable = true;

    config = {
      ### Inputs
      #
      # Touchpad
      input."type=touchpad" = {
        events = if cfg.enableTouchpad then "enabled" else "disabled";
      };
      # TODO: Keyboard

      ### Outputs
      #
      # Wallpaper
      output."*".bg = if cfg.wallpaper == "" then "#000000 solid_color" else "${cfg.wallpaper} fill";

      ### Seats
      #
      # Cursor
      seat."*".xcursor_theme = "${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}";

      ### Programs
      #
      # Terminal
      terminal = cfg.terminal;
      menu = "${pkgs.dmenu}/bin/dmenu_path | ${pkgs.bemenu}/bin/bemenu | ${pkgs.findutils}/bin/xargs swaymsg exec --";
      # Startup
      startup = [
        # Dex for autostart
        { command = "${pkgs.dex}/bin/dex -ae sway"; }
        # Waybar
        { command = "systemctl --user restart waybar"; always = true; }
        # Startup programs
        { command = "${pkgs.flameshot}/bin/flameshot"; }
        { command = "${config.programs.firefox.package}/bin/firefox"; }
        { command = "${pkgs.discord}/bin/discord"; }
      ];

      ### Keybindings
      #
      # Main modifier
      modifier = mod;
      keybindings = lib.mkOptionDefault
        ({
          ## Splits
          "${mod}+v" = "split v";
          "${mod}+Shift+v" = "split h";
          ## Run
          "${mod}+r" = "exec ${config.wayland.windowManager.sway.config.menu}";
          "${mod}+Shift+r" = "mode resize";
          ## Screenshot
          "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";
          ## Locking
          "${mod}+semicolon" = "exec ${pkgs.swaylock}/bin/swaylock"
            + (if cfg.wallpaper == "" then "" else " -i ${cfg.wallpaper} -s fit")
            + " -l -k";
        } // (
          # Map the workspaces
          builtins.listToAttrs (lib.flatten (map
            (key: [
              {
                name = "${mod}+${key}";
                value = "workspace ${builtins.getAttr key wsAttrs}";
              }
              {
                name = "${mod}+Shift+${key}";
                value = "move to workspace ${builtins.getAttr key wsAttrs}";
              }
            ])
            (builtins.attrNames wsAttrs))
          )));

      ### Fonts
      #
      fonts = {
        names = [ "monospace" "FontAwesome5Free" ];
        size = cfg.fontSize;
      };

      ### Workspaces
      #
      # Default workspace
      defaultWorkspace = "workspace ${builtins.elemAt workspaces 0}";
      # Back and Forth
      workspaceAutoBackAndForth = true;

      ### Windows
      #
      # Border
      window.border = 2;
      # Assigning windows to workspaces
      assigns = {
        "${builtins.elemAt workspaces 0}" = [
          { class = "^firefox$"; }
        ];
        "${builtins.elemAt workspaces 1}" = [
          { class = "^(d|D)iscord$"; }
        ];
      };
      focus.followMouse = true;
      focus.mouseWarping = true;
      focus.newWindow = "urgent";
      # Gaps
      gaps.outer = 3;
      gaps.inner = 4;
      gaps.smartBorders = "on";
      gaps.smartGaps = true;

      ### Bars
      #
      # Enable top bar, as waybar
      bars = [{
        command = config.programs.waybar.package + "/bin/waybar";
        position = "top";
      }];
    };
    ### Misc
    #
    # xwayland
    xwayland = true;
    # swaynag
    swaynag.enable = true;
    # Environment Variables
    extraSessionCommands = ''
      export MOZ_ENABLE_WAYLAND=1
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    '';
    # Extra
    wrapperFeatures.base = true;
    wrapperFeatures.gtk = true;

    # Fix D-Bus starting up
    extraConfig = ''
      exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK && \
           hash dbus-update-activation-environment 2>/dev/null && \
           dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK && \
           systemctl --user start sway-session.target
    '';
  };

  config.systemd.user.targets.sway-session = mkIf cfg.enable {
    Unit = {
      Description = "sway compositor session";
      Documentation = [ "man:systemd.special(7)" ];
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  config.programs.waybar = mkIf cfg.enable {
    enable = true;
    settings = [
      # Top bar
      {
        position = "top";
        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];
        modules-center = [
          "sway/window"
        ];
        modules-right = [
          "tray"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "backlight"
        ] ++ (
          if cfg.enableLaptopBars
          then [ "battery" "battery#bat2" ]
          else [ ]
        ) ++ [
          "clock"
        ];

        modules = {
          "sway/mode" = {
            format = "<span style=\"italic\">{}</span>";
          };
          "tray" = {
            icon-size = 21;
            spacing = 10;
          };
          "clock" = {
            tooltip-format = "{:%Y-%m-%d | %H:%M}";
            format-alt = "{:%Y-%m-%d}";
          };
          "cpu" = {
            format = "{usage}% ";
          };
          "memory" = {
            format = "{}% ";
          };
          "temperature" = {
            # thermal-zone = 2;
            # hwmon-path" = "/sys/class/hwmon/hwmon2/temp1_input";
            critical-threshold = 80;
            # format-critical = "{temperatureC}°C ";
            format = "{temperatureC}°C ";
          };
          "backlight" = {
            # device = "acpi_video1";
            format = "{percent}% {icon}";
            states = [ 0 50 ];
            format-icons = [ "" "" ];
          };
          "battery" = mkIf cfg.enableLaptopBars {
            states = {
              good = 95;
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            # format-good = ""; # An empty format will hide the module
            # format-full = "";
            format-icons = [ "" "" "" "" "" ];
          };
          "battery#bat2" = mkIf cfg.enableLaptopBars {
            bat = "BAT2";
          };
          "network" = {
            # interface = wlp2s0 # (Optional) To force the use of this interface
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
            format-disconnected = "Disconnected ⚠";
            interval = 7;
          };
          "pulseaudio" = {
            # scroll-step = 1;
            format = "{volume}% {icon}";
            format-bluetooth = "{volume}% {icon}";
            format-muted = "";
            format-icons = {
              headphones = "";
              handsfree = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [ "" "" ];
            };
            on-click = "pavucontrol";
          };
        };
      }
    ];
    style = ''
      * {
          border: none;
          border-radius: 0;
          font-family: IBM Plex Mono,'Font Awesome 5', 'SFNS Display',  Helvetica, Arial, sans-serif;
          font-size: 13px;
          min-height: 0;
      }

      window#waybar {
          background: rgba(43, 48, 59, 0.5);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: #ffffff;
      }

      window#waybar.hidden {
          opacity: 0.0;
      }
      /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
      #workspaces button {
          padding: 0 5px;
          background: transparent;
          color: #ffffff;
          border-bottom: 3px solid transparent;
      }

      #workspaces button.focused {
          background: #64727D;
          border-bottom: 3px solid #ffffff;
      }

      #workspaces button.urgent {
          background-color: #eb4d4b;
      }

      #mode {
          background: #64727D;
          border-bottom: 3px solid #ffffff;
      }

      #clock, #battery, #cpu, #memory, #temperature, #backlight, #network, #pulseaudio, #custom-media, #tray, #mode, #idle_inhibitor {
          padding: 0 10px;
          margin: 0 5px;
      }

      #clock {
          background-color: #64727D;
      }

      #battery {
          background-color: #ffffff;
          color: #000000;
      }

      #battery.charging {
          color: #ffffff;
          background-color: #26A65B;
      }

      @keyframes blink {
          to {
              background-color: #ffffff;
              color: #000000;
          }
      }

      #battery.critical:not(.charging) {
          background: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      #cpu {
          background: #2ecc71;
          color: #000000;
      }

      #memory {
          background: #9b59b6;
      }

      #backlight {
          background: #90b1b1;
      }

      #network {
          background: #2980b9;
      }

      #network.disconnected {
          background: #f53c3c;
      }

      #pulseaudio {
          background: #f1c40f;
          color: #000000;
      }

      #pulseaudio.muted {
          background: #90b1b1;
          color: #2a5c45;
      }

      #custom-media {
          background: #66cc99;
          color: #2a5c45;
      }

      .custom-spotify {
          background: #66cc99;
      }

      .custom-vlc {
          background: #ffa000;
      }

      #temperature {
          background: #f0932b;
      }

      #temperature.critical {
          background: #eb4d4b;
      }

      #tray {
          background-color: #2980b9;
      }

      #idle_inhibitor {
          background-color: #2d3436;
      }

      #idle_inhibitor.activated {
          background-color: #ecf0f1;
          color: #2d3436;
      }
    '';
  };

  config.home.packages = mkIf cfg.enable (with pkgs; [
    # Needed for QT_QPA_PLATFORM
    qt5.qtwayland
    # For waybar
    font-awesome
  ]);
}
