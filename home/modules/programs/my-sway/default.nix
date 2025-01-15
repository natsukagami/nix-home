{ pkgs, lib, options, config, osConfig, ... }:
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
  extraWorkspaces = {
    mail = "📧 Email";
  };
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

  screenshotEditScript = pkgs.writeScriptBin "screenshot" ''
    #! ${pkgs.fish}/bin/fish

    ${pkgs.grim}/bin/grim -g (${pkgs.slurp}/bin/slurp) - | ${pkgs.swappy}/bin/swappy -f -
  '';
  playerctl = "${pkgs.playerctl}/bin/playerctl";
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
      default = config.linux.graphical.wallpaper;
    };
    terminal = mkOption {
      type = types.str;
      description = "The command to the terminal emulator to be used";
      default = lib.getExe config.linux.graphical.defaults.terminal.package;
    };
    browser = mkOption {
      type = types.str;
      description = "The command for the browser";
      default = lib.getExe config.linux.graphical.defaults.webBrowser.package;
    };

    enableLaptop = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to enable laptop-specific stuff";
      default = true;
    };

    lockCmd = mkOption {
      type = types.str;
      description = "The screen lock command";
      default = "${pkgs.swaylock}/bin/swaylock"
        + (if cfg.wallpaper == "" then "" else " -i ${cfg.wallpaper} -s fill")
        + " -l -k";
    };
  };

  # Enable waybar
  config.programs.my-waybar = mkIf cfg.enable {
    enable = true;
    fontSize = mkDefault cfg.fontSize;
    enableLaptopBars = mkDefault cfg.enableLaptop;
    terminal = mkDefault cfg.terminal;
  };

  config.wayland.windowManager.sway = mkIf cfg.enable {
    enable = true;
    systemd.enable = true;
    systemd.variables = options.wayland.windowManager.sway.systemd.variables.default ++ [
      "PATH" # for portals
      "XDG_DATA_DIRS" # For extra icons
      "XDG_DATA_HOME" # For extra icons
    ] ++ lib.optionals osConfig.services.desktopManager.plasma6.enable [
      "XDG_MENU_PREFIX"
    ];
    systemd.extraCommands = options.wayland.windowManager.sway.systemd.extraCommands.default
      ++ [
      "systemctl --user restart xdg-desktop-portal.service"
    ];

    checkConfig = false; # Not working atm
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
        # IME
        { command = "fcitx5"; }
      ];

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
        "${mod}+shift+p" = "exec rofi-rbw-script";
      } // {
        ## Splits
        "${mod}+v" = "split v";
        "${mod}+Shift+v" = "split h";
        ## Run
        "${mod}+r" = "exec ${config.wayland.windowManager.sway.config.menu}";
        "${mod}+Shift+r" = "mode resize";
        ## Screenshot
        "Print" = "exec ${screenshotScript}/bin/screenshot";
        "Shift+Print" = "exec ${screenshotEditScript}/bin/screenshot";
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
      {
        # Extra workspaces
        "${mod}+asciicircum" = "workspace ${extraWorkspaces.mail}";
        "${mod}+shift+asciicircum" = "move to workspace ${extraWorkspaces.mail}";
      } //
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
          { app_id = "^firefox$"; }
          { app_id = "^librewolf$"; }
          { app_id = "^zen$"; }
        ];
        "${builtins.elemAt workspaces 1}" = [
          { class = "^((d|D)iscord|((A|a)rm(c|C)ord))$"; }
          { class = "VencordDesktop"; }
          { app_id = "VencordDesktop"; }
          { class = "vesktop"; }
          { app_id = "vesktop"; }

          { class = "Slack"; }
        ];
        ${extraWorkspaces.mail} = [
          { app_id = "thunderbird"; }
          { app_id = "evolution"; }
        ];
      };
      # Commands
      window.commands = [
        { criteria = { title = ".*"; }; command = "inhibit_idle fullscreen"; }
      ] ++ (
        # Floating assignments
        let
          criterias = [
            { app_id = ".*float.*"; }
            { app_id = "org\\.freedesktop\\.impl\\.portal\\.desktop\\..*"; }
            { class = ".*float.*"; }
            { title = "Extension: .*Bitwarden.*"; }
          ];
          toCommand = criteria: { inherit criteria; command = "floating enable"; };
        in
        map toCommand criterias
      );
      # Focus
      focus.followMouse = true;
      focus.mouseWarping = true;
      focus.newWindow = "urgent";
      # Gaps
      gaps.outer = 4;
      gaps.inner = 4;
      gaps.smartBorders = "on";
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
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export QT_IM_MODULE=fcitx
      export GTK_IM_MODULE=fcitx # Til text-input is merged
      # export NIXOS_OZONE_WL=1 # Until text-input is merged

    '' + (if config.services.gnome-keyring.enable then ''
      # gnome-keyring
      if type gnome-keyring-daemon >/dev/null; then
        eval `gnome-keyring-daemon`
        export SSH_AUTH_SOCK
      fi
    '' else "") + lib.optionalString osConfig.services.desktopManager.plasma6.enable ''
      export XDG_MENU_PREFIX=plasma-
    '';
    # Extra
    wrapperFeatures.base = true;
    wrapperFeatures.gtk = true;

    extraConfig =
      (if cfg.enableLaptop then ''
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
        smart_corner_radius on
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
        ''}
      '';
  };

  config.services.swayidle = mkIf cfg.enable {
    enable = true;
    systemdTarget = "sway-session.target";
    timeouts = [
      # Lock after 15 minutes of idle
      # { timeout = 15 * 60; command = cfg.lockCmd; }
    ];
    events = [
      { event = "lock"; command = cfg.lockCmd; }
      { event = "before-sleep"; command = cfg.lockCmd; }
    ];
  };

  config.home.packages = mkIf cfg.enable (with pkgs; [
    # Needed for QT_QPA_PLATFORM
    kdePackages.qtwayland
    # For waybar
    font-awesome
  ]);

  config.programs.rofi = mkIf cfg.enable {
    font = lib.mkForce "monospace ${toString cfg.fontSize}";
  };
}

