{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.my-niri;

  sh = config.lib.niri.actions.spawn "sh" "-c";
  playerctl = lib.getExe pkgs.playerctl;
  amixer = lib.getExe' pkgs.alsa-utils "amixer";
  brightnessctl = lib.getExe pkgs.brightnessctl;
  app-menu = "${pkgs.dmenu}/bin/dmenu_path | ${pkgs.bemenu}/bin/bemenu | ${pkgs.findutils}/bin/xargs niri msg action spawn --";

  wallpaper = config.linux.graphical.wallpaper;
  blurred-wallpaper = pkgs.runCommandNoCC "blurred-${baseNameOf wallpaper}" { } ''
    ${lib.getExe pkgs.imagemagick} convert -blur 0x25 ${wallpaper} $out
  '';

  xwayland-display = ":0";

  # Override for lack of per-keyboard layout
  ydotool-en = pkgs.writeScriptBin "ydotool" ''
    #!/usr/bin/env sh
    niri msg action switch-layout 1 && fcitx5-remote -c # us
    ${lib.getExe pkgs.ydotool} "$@"
    niri msg action switch-layout 0 # ja
  '';
in
{
  options.programs.my-niri = {
    enable = lib.mkEnableOption "My own niri configuration";

    enableLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable laptop options";
    };

    lock-command = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "The command to lock the screen";
      default = [
        "${pkgs.swaylock}/bin/swaylock"
      ]
      ++ (
        if wallpaper == "" then
          [ "" ]
        else
          [
            "-i"
            "${wallpaper}"
            "-s"
            "fill"
          ]
      )
      ++ [
        "-l"
        "-k"
      ];
    };

    workspaces = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "workspace name";
            };
            fixed = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "whether workspace always exists";
            };
            monitor = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Default monitor to spawn workspace in";
            };
          };
        }
      );
      description = "A mapping of ordering to workspace names, for fixed workspaces";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ ydotool-en ];
    programs.my-niri.workspaces = {
      # Default workspaces, always there
      "01" = {
        name = "🌏 web";
      };
      "02" = {
        name = "💬 chat";
      };
      "03" = {
        name = "⚙️ code";
      };
      "99" = {
        name = "📧 Email";
      };
    };
    systemd.user.services.swaync.Install.WantedBy = [ "niri.service" ];
    systemd.user.services.swaync.Unit.After = [ "niri.service" ];
    systemd.user.targets.tray.Unit.After = [ "niri.service" ];
    systemd.user.targets.xwayland.Unit.After = [ "niri.service" ];

    programs.my-waybar = {
      enable = true;
      enableLaptopBars = lib.mkDefault cfg.enableLaptop;
    };
    systemd.user.services.waybar.Unit.After = [ "niri.service" ];
    systemd.user.services.waybar.Install.WantedBy = [ "niri.service" ];

    # xwayland-satellite
    systemd.user.services.niri-xwayland-satellite = lib.mkIf cfg.enable {
      Unit = {
        Description = "XWayland Client for niri";
        PartOf = [ "xwayland.target" ];
        Before = [
          "xwayland.target"
          "xdg-desktop-autostart.target"
        ];
        After = [ "niri.service" ];
      };
      Install.WantedBy = [ "niri.service" ];
      Install.UpheldBy = [ "niri.service" ];
      Service.Slice = "session.slice";
      Service.Type = "notify";
      Service.ExecStart = "${lib.getExe pkgs.xwayland-satellite} ${xwayland-display}";
      Service.ExecStartPost = [ "systemctl --user set-environment DISPLAY=${xwayland-display}" ];
      Service.ExecStopPost = [ "systemctl --user unset-environment" ];
    };

    programs.niri.settings = {
      environment = {
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_IM_MODULE = "fcitx";
        # export NIXOS_OZONE_WL=1 # Until text-input is merged
        DISPLAY = xwayland-display;
      }
      // lib.optionalAttrs osConfig.services.desktopManager.plasma6.enable {
        XDG_MENU_PREFIX = "plasma-";
      };
      input.keyboard.xkb = {
        layout = "jp,us";
      };
      input.touchpad = lib.mkIf cfg.enableLaptop {
        tap = true;
        dwt = true;
        natural-scroll = true;
        middle-emulation = true;
      };
      input.mouse = {
        accel-profile = "flat";
      };
      input.warp-mouse-to-focus.enable = true;
      input.focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };

      outputs =
        let
          eachMonitor = _: monitor: {
            name = monitor.meta.niriName or monitor.name; # Niri might not find the monitor by name
            value = {
              mode = monitor.meta.mode;
              position = monitor.meta.fixedPosition or null;
              scale = monitor.scale or 1;
              variable-refresh-rate = (monitor.adaptive_sync or "off") == "on";
            };
          };
        in
        lib.mapAttrs' eachMonitor config.common.monitors;

      spawn-at-startup = [
        # Wallpaper
        {
          command = [
            "${lib.getExe pkgs.swaybg}"
            "-i"
            (toString wallpaper)
            "-m"
            "fill"
          ];
        }
        {
          command = [
            "${lib.getExe pkgs.swaybg}"
            "-i"
            (toString blurred-wallpaper)
            "-m"
            "fill"
            "-n"
            "wallpaper-blurred"
          ];
        }
        # Waybar
        {
          command = [
            "systemctl"
            "--user"
            "start"
            "xdg-desktop-portal-gtk.service"
            "xdg-desktop-portal.service"
          ];
        }
      ];

      layout = {
        background-color = "transparent";
        gaps = 16;
        preset-column-widths = [
          { proportion = 1. / 3.; }
          { proportion = 1. / 2.; }
          { proportion = 2. / 3.; }
        ];
        default-column-width.proportion = 1. / 2.;

        focus-ring = {
          width = 4;
          active.gradient = {
            from = "#00447AFF";
            to = "#71C4FFAA";
            angle = 45;
          };
          inactive.color = "#505050";
        };
        border.enable = false;
        struts =
          let
            v = 8;
          in
          {
            left = v;
            right = v;
            bottom = v;
            top = v;
          };
      };

      prefer-no-csd = true;

      workspaces =
        let
          fixedWorkspaces = lib.filterAttrs (_: w: w.fixed) cfg.workspaces;
          workspaceConfig = lib.mapAttrs (
            _: w:
            {
              inherit (w) name;
            }
            // (lib.optionalAttrs (w.monitor != null) {
              open-on-output = w.monitor;
            })
          ) fixedWorkspaces;
        in
        workspaceConfig;

      window-rules = [
        # Rounded Corners
        {
          geometry-corner-radius =
            let
              v = 8.0;
            in
            {
              bottom-left = v;
              bottom-right = v;
              top-left = v;
              top-right = v;
            };
          clip-to-geometry = true;
        }
        # Workspace assignments
        {
          open-on-workspace = cfg.workspaces."01".name;
          open-maximized = true;
          matches = [
            {
              at-startup = true;
              app-id = "^firefox$";
            }
            {
              at-startup = true;
              app-id = "^librewolf$";
            }
            {
              at-startup = true;
              app-id = "^zen$";
            }
          ];
        }
        {
          open-on-workspace = cfg.workspaces."02".name;
          open-maximized = true;
          matches = [
            { title = "^((d|D)iscord|((A|a)rm(c|C)ord))$"; }
            { title = "VencordDesktop"; }
            { app-id = "VencordDesktop"; }
            { title = "vesktop"; }
            { app-id = "vesktop"; }

            { title = "Slack"; }
          ];
        }
        {
          open-on-workspace = cfg.workspaces."99".name;
          open-maximized = true;
          matches = [
            { app-id = "thunderbird"; }
            { app-id = "evolution"; }
          ];
        }
        # Floating
        {
          open-floating = true;
          matches = [
            { app-id = ".*float.*"; }
            { app-id = "org\\.freedesktop\\.impl\\.portal\\.desktop\\..*"; }
            { title = ".*float.*"; }
            { title = "Extension: .*Bitwarden.*"; }
            { app-id = "Rofi"; }
          ];
        }

        # xwaylandvideobridge
        {
          matches = [ { app-id = "^xwaylandvideobridge$"; } ];
          open-floating = true;
          focus-ring.enable = false;
          opacity = 0.0;
          default-floating-position = {
            x = 0;
            y = 0;
            relative-to = "bottom-right";
          };
          min-width = 1;
          max-width = 1;
          min-height = 1;
          max-height = 1;
        }

        # Kitty dimming
        {
          matches = [ { app-id = "kitty"; } ];
          excludes = [ { is-focused = true; } ];
          opacity = 0.95;
        }
      ];

      layer-rules = [
        {
          matches = [ { namespace = "^swaync-.*"; } ];
          block-out-from = "screen-capture";
        }
        {
          matches = [ { namespace = "^wallpaper-blurred$"; } ];
          place-within-backdrop = true;
        }
      ];

      binds =
        with config.lib.niri.actions;
        let
          move-column-to-workspace = workspace: { move-column-to-workspace = workspace; };
        in
        {
          # Mod-Shift-/, which is usually the same as Mod-?,
          # shows a list of important hotkeys.
          "Mod+Shift+Slash".action = show-hotkey-overlay;

          # Some basic spawns
          "Mod+Return".action = spawn (lib.getExe config.linux.graphical.defaults.terminal.package);
          "Mod+Space".action = spawn "rofi" "-show" "drun";
          "Mod+R".action = sh app-menu;
          "Mod+Semicolon".action = spawn cfg.lock-command;
          "Mod+Shift+P".action = spawn "rofi-rbw-script";

          # Audio and Volume
          "XF86AudioPrev" = {
            action = spawn playerctl "previous";
            allow-when-locked = true;
          };
          "XF86AudioPlay" = {
            action = spawn playerctl "play-pause";
            allow-when-locked = true;
          };
          "Shift+XF86AudioPlay" = {
            action = spawn playerctl "stop";
            allow-when-locked = true;
          };
          "XF86AudioNext" = {
            action = spawn playerctl "next";
            allow-when-locked = true;
          };
          "XF86AudioRecord" = {
            action = spawn amixer "-q" "set" "Capture" "toggle";
            allow-when-locked = true;
          };
          "XF86AudioMute" = {
            action = spawn amixer "-q" "set" "Master" "toggle";
            allow-when-locked = true;
          };
          "XF86AudioLowerVolume" = {
            action = spawn amixer "-q" "set" "Master" "3%-";
            allow-when-locked = true;
          };
          "XF86AudioRaiseVolume" = {
            action = spawn amixer "-q" "set" "Master" "3%+";
            allow-when-locked = true;
          };

          # Backlight
          "XF86MonBrightnessDown".action = spawn brightnessctl "s" "10%-";
          "XF86MonBrightnessUp".action = spawn brightnessctl "s" "10%+";
          "Shift+XF86MonBrightnessDown".action = spawn brightnessctl "-d" "kbd_backlight" "s" "25%-";
          "Shift+XF86MonBrightnessUp".action = spawn brightnessctl "-d" "kbd_backlight" "s" "25%+";

          "Mod+Shift+Q".action = close-window;

          "Mod+Left".action = focus-column-or-monitor-left;
          "Mod+Right".action = focus-column-or-monitor-right;
          "Mod+Up".action = focus-window-or-workspace-up;
          "Mod+Down".action = focus-window-or-workspace-down;
          "Mod+H".action = focus-column-or-monitor-left;
          "Mod+L".action = focus-column-or-monitor-right;
          "Mod+K".action = focus-window-or-workspace-up;
          "Mod+J".action = focus-window-or-workspace-down;

          "Mod+Shift+Left".action = move-column-left-or-to-monitor-left;
          "Mod+Shift+Right".action = move-column-right-or-to-monitor-right;
          "Mod+Shift+Up".action = move-window-up-or-to-workspace-up;
          "Mod+Shift+Down".action = move-window-down-or-to-workspace-down;
          "Mod+Shift+H".action = move-column-left-or-to-monitor-left;
          "Mod+Shift+L".action = move-column-right-or-to-monitor-right;
          "Mod+Shift+K".action = move-window-up-or-to-workspace-up;
          "Mod+Shift+J".action = move-window-down-or-to-workspace-down;

          "Mod+Bracketleft".action = focus-column-first;
          "Mod+Bracketright".action = focus-column-last;
          "Mod+Shift+Bracketleft".action = move-column-to-first;
          "Mod+Shift+Bracketright".action = move-column-to-last;

          "Mod+Ctrl+K".action = move-workspace-up;
          "Mod+Ctrl+J".action = move-workspace-down;

          "Mod+I".action = focus-monitor-left;
          "Mod+O".action = focus-monitor-right;
          "Mod+Shift+I".action = move-workspace-to-monitor-left;
          "Mod+Shift+O".action = move-workspace-to-monitor-right;

          # Mouse bindings
          "Mod+WheelScrollDown" = {
            action = focus-workspace-down;
            cooldown-ms = 150;
          };
          "Mod+WheelScrollUp" = {
            action = focus-workspace-up;
            cooldown-ms = 150;
          };
          "Mod+Shift+WheelScrollDown" = {
            action = move-column-to-workspace-down;
            cooldown-ms = 150;
          };
          "Mod+Shift+WheelScrollUp" = {
            action = move-column-to-workspace-up;
            cooldown-ms = 150;
          };

          "Mod+WheelScrollRight".action = focus-column-right;
          "Mod+WheelScrollLeft".action = focus-column-left;
          "Mod+Shift+WheelScrollRight".action = move-column-right;
          "Mod+Shift+WheelScrollLeft".action = move-column-left;

          # You can refer to workspaces by index. However, keep in mind that
          # niri is a dynamic workspace system, so these commands are kind of
          # "best effort". Trying to refer to a workspace index bigger than
          # the current workspace count will instead refer to the bottommost
          # (empty) workspace.
          #
          # For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
          # will all refer to the 3rd workspace.
          "Mod+A".action = focus-workspace (cfg.workspaces."01".name);
          "Mod+Shift+A".action = move-column-to-workspace (cfg.workspaces."01".name);
          "Mod+S".action = focus-workspace (cfg.workspaces."02".name);
          "Mod+Shift+S".action = move-column-to-workspace (cfg.workspaces."02".name);
          "Mod+D".action = focus-workspace (cfg.workspaces."03".name);
          "Mod+Shift+D".action = move-column-to-workspace (cfg.workspaces."03".name);
          "Mod+asciicircum".action = focus-workspace (cfg.workspaces."99".name);
          "Mod+Shift+asciicircum".action = move-column-to-workspace (cfg.workspaces."99".name);

          "Mod+Tab".action = focus-workspace-previous;

          "Mod+Comma".action = consume-or-expel-window-left;
          "Mod+Period".action = consume-or-expel-window-right;

          "Mod+W".action = switch-preset-column-width;
          "Mod+Shift+W".action = switch-preset-window-height;
          "Mod+Ctrl+W".action = reset-window-height;
          "Mod+F".action = maximize-column;
          "Mod+Shift+F".action = fullscreen-window;
          "Mod+E".action = center-column;

          "Mod+Minus".action = set-column-width "-10%";
          "Mod+At".action = set-column-width "+10%";
          "Mod+Shift+Minus".action = set-window-height "-10%";
          "Mod+Shift+At".action = set-window-height "+10%";

          "Mod+V".action = switch-focus-between-floating-and-tiling;
          "Mod+Shift+V".action = toggle-window-floating;
          "Mod+Shift+Space".action = toggle-window-floating; # Sway compat

          "Print".action = screenshot;
          "Ctrl+Print".action.screenshot-screen = [ ];
          "Shift+Print".action = screenshot-window;

          "Mod+Shift+E".action = quit;
        }
        // (builtins.listToAttrs (
          builtins.concatMap
            (id: [
              {
                name = "Mod+${toString (if id == 10 then 0 else id)}";
                value.action = focus-workspace id;
              }
              {
                name = "Mod+Shift+${toString (if id == 10 then 0 else id)}";
                value.action = move-column-to-workspace id;
              }
            ])
            [
              1
              2
              3
              4
              5
              6
              7
              8
              9
              10
            ]
        ));
    };
  };
}
