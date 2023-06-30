{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.programs.my-sway;
  swayCfg = config.wayland.windowManager.sway;

  mod = "Mod4";
  # List of workspaces
  workspaces = [
    "1:🌏 web"
    "2:💬 chat"
    "3:⚙️ code"
    "4:🎶 music"
    "5:🔧 extra"
    "6:🧰 6"
    "7:🔩 7"
    "8:🛠️ 8"
    "9:🔨 9"
    "10:🎲 misc"
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

  screenshotScript = pkgs.writeScriptBin "screenshot" ''
    #! ${pkgs.fish}/bin/fish

    ${pkgs.grim}/bin/grim -g (${pkgs.slurp}/bin/slurp) - | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  ignored-devices = [ "Surface_Headphones" ];
  playerctl = "${pkgs.playerctl}/bin/playerctl --ignore-player=${strings.concatStringsSep "," ignored-devices}";

in
{
  # imports = [ ./ibus.nix ];

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
      default = "${config.programs.kitty.package}/bin/kitty";
    };
    browser = mkOption {
      type = types.str;
      description = "The command for the browser";
      default = "${pkgs.firefox-wayland}/bin/firefox";
    };
    discord = mkOption {
      type = types.nullOr types.str;
      description = "The command for discord";
      default = "${config.nki.programs.discord.package}/bin/discord";
    };

    lockCmd = mkOption {
      type = types.str;
      description = "The screen lock command";
      default = "${pkgs.swaylock}/bin/swaylock"
        + (if cfg.wallpaper == "" then "" else " -i ${cfg.wallpaper} -s fill")
        + " -l -k";
    };
    enableLaptopBars = mkOption {
      type = types.bool;
      description = "Whether to enable laptop-specific bars (battery)";
      default = true;
    };
    enableMpd = mkOption {
      type = types.bool;
      description = "Whether to enable mpd on waybar";
      default = false;
    };

    waybar = {
      makeBars = mkOption {
        type = types.raw;
        description = "Create bars with the barWith function, return a list of bars";
        default = barWith: [ (barWith { }) ];
      };
      extraSettings = mkOption {
        type = types.raw;
        description = "Extra settings to be included with every default bar";
        default = { };
      };
      extraStyle = mkOption {
        type = types.str;
        description = "Additional style for the default waybar";
        default = "";
      };
    };
  };

  config.wayland.windowManager.sway = mkIf cfg.enable {
    enable = true;
    systemdIntegration = true;

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
        { command = "${cfg.browser}"; }
        { command = "thunderbird"; } # Rely on system package with plugins
      ] ++ (if cfg.discord != null then [
        { command = "${cfg.discord}"; }
      ] ++ lib.lists.optional
        (!pkgs.stdenv.isAarch64)
        (
          { command = "${pkgs.premid}/bin/premid"; }
        ) else [ ]);

      ### Keybindings
      #
      # Main modifier
      modifier = mod;
      keybindings = {
        ### Default Bindings
        #
        ## App management
        "${mod}+Return" = "exec ${swayCfg.config.terminal}";
        "${mod}+Shift+q" = "kill";
        "${mod}+d" = "exec ${swayCfg.config.menu}";
        ## Windowing
        # Focus
        "${mod}+${swayCfg.config.left}" = "focus left";
        "${mod}+${swayCfg.config.down}" = "focus down";
        "${mod}+${swayCfg.config.up}" = "focus up";
        "${mod}+${swayCfg.config.right}" = "focus right";
        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";
        # Move
        "${mod}+Shift+${swayCfg.config.left}" = "move left";
        "${mod}+Shift+${swayCfg.config.down}" = "move down";
        "${mod}+Shift+${swayCfg.config.up}" = "move up";
        "${mod}+Shift+${swayCfg.config.right}" = "move right";
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";
        # Toggles
        "${mod}+f" = "fullscreen toggle";
        "${mod}+a" = "focus parent";
        # Layouts
        "${mod}+s" = "layout stacking";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        # Floating
        "${mod}+Shift+space" = "floating toggle";
        # Scratchpad
        "${mod}+Shift+minus" = "move scratchpad";
        # Resize
        "${mod}+r" = "mode resize";
        "${mod}+minus" = "scratchpad show";
        ## Reload and exit
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+e" =
          "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
        # Launcher
        "${mod}+space" = "exec rofi -show drun";
        "${mod}+tab" = "exec ${./rofi-window.py}";
      } // {
        ## Splits
        "${mod}+v" = "split v";
        "${mod}+Shift+v" = "split h";
        ## Run
        "${mod}+r" = "exec ${config.wayland.windowManager.sway.config.menu}";
        "${mod}+Shift+r" = "mode resize";
        ## Screenshot
        "Print" = "exec ${screenshotScript}/bin/screenshot";
        ## Locking
        "${mod}+semicolon" = "exec ${cfg.lockCmd}";
        ## Multimedia
        "XF86AudioPrev" = "exec ${playerctl} previous";
        "XF86AudioPlay" = "exec ${playerctl} play-pause";
        "Shift+XF86AudioPlay" = "exec ${playerctl} stop";
        "XF86AudioNext" = "exec ${playerctl} next";
        "XF86AudioRecord" = "exec ${pkgs.alsa-utils}/bin/amixer -q set Capture toggle";
        "XF86AudioMute" = "exec ${pkgs.alsa-utils}/bin/amixer -q set Master toggle";
        "XF86AudioLowerVolume" = "exec ${pkgs.alsa-utils}/bin/amixer -q set Master 3%-";
        "XF86AudioRaiseVolume" = "exec ${pkgs.alsa-utils}/bin/amixer -q set Master 3%+";
        ## Backlight
        "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl s 10%-";
        "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl s 10%+";
        "Shift+XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl -d kbd_backlight s 25%-";
        "Shift+XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl -d kbd_backlight s 25%+";
      } //
      # Map the workspaces
      (builtins.listToAttrs (lib.flatten (map
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
      )) //
      # Move workspaces between outputs
      {
        "${mod}+ctrl+h" = "move workspace to output left";
        "${mod}+ctrl+l" = "move workspace to output right";
      };

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
      window.border = 4;
      # Assigning windows to workspaces
      assigns = {
        "${builtins.elemAt workspaces 0}" = [
          { class = "^firefox$"; }
        ];
        "${builtins.elemAt workspaces 1}" = [
          { class = "^((d|D)iscord|((A|a)rm(c|C)ord))$"; }
        ];
        "📧 Email" = [
          { app_id = "thunderbird"; }
        ];
      };
      # Commands
      window.commands = [
        { criteria = { title = ".*"; }; command = "inhibit_idle fullscreen"; }
        { criteria = { app_id = ".*float.*"; }; command = "floating enable"; }
        { criteria = { class = ".*float.*"; }; command = "floating enable"; }
      ];
      # Focus
      focus.followMouse = true;
      focus.mouseWarping = true;
      focus.newWindow = "urgent";
      # Gaps
      gaps.outer = 4;
      gaps.inner = 4;
      gaps.smartBorders = "off"; # until swayfx fixes clipping bug
      gaps.smartGaps = false;

      ### Bars
      # Let systemd manage it
      bars = [ ];
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

    '' + (if config.services.gnome-keyring.enable then ''
      # gnome-keyring
      eval `gnome-keyring-daemon -r -d -c secrets,ssh,pkcs11`
      export SSH_AUTH_SOCK
    '' else "");
    # Extra
    wrapperFeatures.base = true;
    wrapperFeatures.gtk = true;

    extraConfig =
      (if cfg.enableLaptopBars then ''
        # Lock screen on lid close
        bindswitch lid:off exec ${cfg.lockCmd}

        # Gesture bindings
        bindgesture swipe:3:right workspace prev
        bindgesture swipe:3:left workspace next
        bindgesture swipe:3:up exec ${./rofi-window.py}
      '' else "") + ''
        ## swayfx stuff
        # Rounded corners
        corner_radius 5
        smart_corner_radius off
        # Shadows
        shadows on
        shadow_blur_radius 5
        # Dimming
        default_dim_inactive 0.0
        for_window [app_id="kitty"] dim_inactive 0.05
        titlebar_separator enable
        # Blur
        for_window [app_id=".*kitty.*"] blur enable
        blur_xray disable
      '' + ''
        # Enable portal stuff
        exec ${pkgs.writeShellScript "start-portals.sh" ''
        # Import the WAYLAND_DISPLAY env var from sway into the systemd user session.
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway

        # Stop any services that are running, so that they receive the new env var when they restart.
        systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
        systemctl --user start pipewire-media-session
        ''}
      '';
  };

  config.services.swayidle = mkIf cfg.enable {
    enable = true;
    timeouts = [
      # Lock after 15 minutes of idle
      { timeout = 15 * 60; command = cfg.lockCmd; }
    ];
  };

  config.programs.waybar =
    let
      barWith = { showMedia ? true, showConnectivity ? true, extraSettings ? { }, ... }: (mkMerge [{
        position = "top";
        modules-left = [
          "sway/workspaces"
          "sway/mode"
          "sway/window"
        ];
        modules-center = [
        ];
        modules-right =
          lib.optional showMedia (if cfg.enableMpd then "mpd" else "custom/media")
          ++ [
            "tray"
            "pulseaudio"
          ] ++ lib.optionals showConnectivity [
            "bluetooth"
            "network"
          ] ++ [
            "cpu"
            "memory"
            "temperature"
          ] ++ lib.optionals cfg.enableLaptopBars [ "battery" "battery#bat2" ]
          ++ [
            "clock"
          ];

        modules = {
          "sway/workspaces" = {
            format = "{name}";
          };
          "sway/mode" = {
            format = "<span style=\"italic\">{}</span>";
          };
          "sway/window" = {
            max-length = 70;
            format = "{title}";
            "rewrite" = {
              "(.*) — Mozilla Firefox" = "[🌎] $1";
              "(.*) - Mozilla Thunderbird" = "[📧] $1";
              "(.*) - Kakoune" = "[⌨️] $1";
              "(.*) - fish" = "[>_] $1";
              "(.*) - Discord" = "[🗨️] $1";
              # ArmCord thing
              "• Discord \\| (.*)" = "[🗨️] $1";
              "\\((\\d+)\\) Discord \\| (.*)" = "[🗨️] {$1} $2";
            };
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
          "bluetooth" = {
            format = " {status}";
            format-connected = " {device_alias}";
            format-connected-battery = " {device_alias} {device_battery_percentage}%";
            # format-device-preference= [ "device1", "device2" ], // preference list deciding the displayed devic;
            tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
            on-click = "${pkgs.blueman}/bin/blueman-manager";
          };
          "pulseaudio" = {
            # scroll-step = 1;
            format = "{volume}% {icon}";
            format-bluetooth = "{volume}% {icon}";
            format-muted = "";
            format-icons = {
              headphones = "";
              handsfree = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [ "" "" ];
            };
            on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          };
          "mpd" = {
            "format" = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) 🎧";
            "format-disconnected" = "Disconnected 🎧";
            "format-stopped" = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped 🎧";
            "interval" = 2;
            "consume-icons" = {
              "on" = " "; # Icon shows only when "consume" is on
            };
            "random-icons" = {
              "off" = "<span color=\"#f53c3c\"></span> "; # Icon grayed out when "random" is off;
              "on" = " ";
            };
            "repeat-icons" = {
              "on" = " ";
            };
            "single-icons" = {
              "on" = "1 ";
            };
            "state-icons" = {
              "paused" = "";
              "playing" = "";
            };
            "tooltip-format" = "MPD (connected)";
            "tooltip-format-disconnected" = "MPD (disconnected)";
            "on-click" = "${pkgs.mpc_cli}/bin/mpc toggle";
            "on-click-right" = "${pkgs.mpc_cli}/bin/mpc stop";
            "on-click-middle" = "${cfg.terminal} --class=kitty_ncmpcpp ${pkgs.ncmpcpp}/bin/ncmpcpp";
          };
          "custom/media" = {
            "format" = "{icon}{}";
            "return-type" = "json";
            "format-icons" = {
              "Playing" = " ";
              "Paused" = " ";
            };
            "max-length" = 80;
            "exec" = "${playerctl} -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
            "on-click" = "${playerctl} play-pause";
          };
        };
      }
        cfg.waybar.extraSettings
        extraSettings]);
    in
    mkIf cfg.enable {
      enable = true;
      systemd.enable = true;
      settings = cfg.waybar.makeBars barWith;
      style = ''
        * {
            border: none;
            border-radius: 0;
            font-family: IBM Plex Mono, 'Font Awesome 5', 'Symbols Nerd Font Mono', 'SFNS Display',  Helvetica, Arial, sans-serif;
            font-size: ${toString cfg.fontSize}px;
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

        #window, #sway, #sway-window {
            padding: 0 10px;
        }

        #mode {
            background: #64727D;
            border-bottom: 3px solid #ffffff;
        }

        #clock, #battery, #cpu, #memory, #temperature, #backlight, #network, #pulseaudio, #bluetooth, #custom-media, #tray, #mode, #idle_inhibitor, #mpd {
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
        }

        #bluetooth {
            background: DarkSlateBlue;
            color: white;
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

        #mpd {
            background-color: teal;
            color: white;
        }
      '' + cfg.waybar.extraStyle;
    };
  config.home.packages = mkIf cfg.enable (with pkgs; [
    # Needed for QT_QPA_PLATFORM
    qt5.qtwayland
    # For waybar
    font-awesome
  ]);
  config.programs.rofi = mkIf cfg.enable {
    enable = true;
    package = pkgs.rofi-wayland;
    cycle = true;
    font = "monospace ${toString cfg.fontSize}";
    terminal = cfg.terminal;
    theme = "Paper";
    plugins = with pkgs; [ rofi-bluetooth rofi-calc rofi-rbw rofi-power-menu ];
  };
}

