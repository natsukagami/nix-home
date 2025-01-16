{ lib, config, pkgs, ... }:
let
  cfg = config.programs.my-waybar;
in
{
  options.programs.my-waybar = {
    enable = lib.mkEnableOption "custom configuration for waybar";
    fontSize = lib.mkOption {
      type = lib.types.float;
      description = "The default font size";
    };
    terminal = lib.mkOption {
      type = lib.types.str;
      description = "The command to the terminal emulator to be used";
      default = "${config.programs.kitty.package}/bin/kitty";
    };

    enableLaptopBars = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to enable laptop-specific bars (battery)";
      default = true;
    };
    enableMpd = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to enable mpd on waybar";
      default = false;
    };

    makeBars = lib.mkOption {
      type = lib.types.raw;
      description = "Create bars with the barWith function, return a list of bars";
      default = barWith: [ (barWith { }) ];
    };
    extraSettings = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      description = "Extra settings to be included with every default bar";
      default = [ ];
    };
    extraStyle = lib.mkOption {
      type = lib.types.lines;
      description = "Additional style for the default waybar";
      default = "";
    };
  };
  config.programs.waybar =
    let
      barWith = { showMedia ? true, showConnectivity ? true, extraSettings ? { }, ... }: lib.mkMerge ([{
        layer = "top";
        position = "top";
        modules-left = [
          "sway/workspaces"
          "sway/mode"
          "sway/window"
          "niri/workspaces"
          "niri/window"
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
          "niri/window" = {
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
            # format = "{:📅 %Y-%m-%d | 🕰️ %H:%M [%Z]}";
            format = "📅 {0:%Y-%m-%d} |️ 🕰️ {0:%H:%M [%Z]}";
            tooltip-format = "\n<span size='9pt' font_family='Noto Sans Mono CJK JP'>{calendar}</span>";
            timezones = [
              "Europe/Zurich"
              "America/Toronto"
              "Asia/Tokyo"
              "Asia/Ho_Chi_Minh"
            ];
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              on-click-right = "mode";
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc6d9'><b>{}</b></span>";
                weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                weekdays = "<span color='#ffcc66'><b>日 月 火 水 木 金 土</b></span>"; # See https://github.com/Alexays/Waybar/issues/3132
                today = "<span color='#ff6699'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click-middle = "mode";
              on-click-right = "tz_up";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
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
          "battery" = lib.mkIf cfg.enableLaptopBars {
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
          "battery#bat2" = lib.mkIf cfg.enableLaptopBars {
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
            "exec" = "${lib.getExe pkgs.playerctl} -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
            "on-click" = "${lib.getExe pkgs.playerctl} play-pause";
          };
        };
      }] ++
      cfg.extraSettings
      ++ [ extraSettings ]);
    in
    lib.mkIf cfg.enable {
      enable = true;
      systemd.enable = true;
      systemd.target = "graphical-session.target";
      settings = cfg.makeBars barWith;
      style = ''
        * {
            border: none;
            border-radius: 0;
            font-family: monospace, 'Font Awesome 5', 'Symbols Nerd Font Mono', 'SFNS Display',  Helvetica, Arial, sans-serif;
            font-size: ${toString (cfg.fontSize * 1.1)}px;
            min-height: 0;
        }

        window#waybar {
            background: rgba(43, 48, 59, 0.8);
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
          padding-left: 1em;
          margin-bottom: 0.4em;
        }

        #mode {
            background: #64727D;
            border-bottom: 3px solid #ffffff;
        }

        /* #clock, #battery, #cpu, #memory, #temperature, #backlight, #network, #pulseaudio, #bluetooth, #custom-media, #tray, #mode, #idle_inhibitor, #mpd { */
        .modules-right > * > * {
          margin: 0.2em 0 0.4em 0;
          padding: 0.2em 0.5em;
          border: 1px solid rgba(0, 0, 0, 0.25);
          border-radius: 0.3em;
        }

        .modules-right > *:not(:last-child) > * {
          margin-right: 0.4em;
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
      '' + cfg.extraStyle;
    };
}
