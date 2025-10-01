{
  pkgs,
  config,
  lib,
  ...
}:
let
  notificationModule =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      swaync = pkgs.swaynotificationcenter;
    in
    with lib;
    mkIf (config.linux.graphical.type == "wayland") {
      services.swaync = {
        enable = true;
        settings.widgets = [
          "inhibitors"
          "title"
          "dnd"
          "mpris"
          "notifications"
        ];
        style = ./swaync.css;
      };

      programs.my-waybar = {
        extraSettings = [
          {
            modules-right = mkAfter [ "custom/swaync" ];
            modules."custom/swaync" = {
              tooltip = false;
              format = "{icon} {}";
              format-icons = {
                notification = "🔔";
                none = "🎐";
                dnd-notification = "🤫";
                dnd-none = "🔕";
                inhibited-notification = "🔔";
                inhibited-none = "🎐";
                dnd-inhibited-notification = "🤫";
                dnd-inhibited-none = "🔕";
              };
              return-type = "json";
              # exec-if = "which swaync-client";
              exec = "${swaync}/bin/swaync-client -swb";
              on-click = "${swaync}/bin/swaync-client -t -sw";
              on-click-right = "${swaync}/bin/swaync-client -d -sw";
              escape = true;
            };
          }
        ];
        extraStyle = mkAfter ''
          #custom-swaync {
              background: #F0FFFF;
              color: #000000;
          }
        '';
      };
    };

  plasmaModule =
    { pkgs, ... }:
    {
      home.packages = with pkgs.kdePackages; [
        discover
        kmail
        kontact
        akonadi
        kdepim-runtime
        kmail-account-wizard
        akonadi-import-wizard
      ];
      xdg.configFile."plasma-workspace/env/wayland.sh".source =
        pkgs.writeScript "plasma-wayland-env.sh" ''
          export NIXOS_OZONE_WL=1
        '';
      xdg.dataFile."dbus-1/services/org.freedesktop.Notifications.service".source =
        "${pkgs.kdePackages.plasma-workspace}/share/dbus-1/services/org.kde.plasma.Notifications.service";
    };

  rofi-rbw-script = pkgs.writeTextFile rec {
    name = "rofi-rbw-script";
    text = ''
      #!/usr/bin/env fish
      set -a PATH ${
        lib.concatMapStringsSep " " (p: "${lib.getBin p}/bin") [
          config.programs.rofi.package
          pkgs.ydotool
          pkgs.rofi-rbw
        ]
      }
      rofi-rbw
    '';
    executable = true;
    destination = "/bin/${name}";
    meta.mainProgram = name;
  };
in
with lib;
{
  imports = [
    notificationModule
    plasmaModule
  ];
  config = mkIf (config.linux.graphical.type == "wayland") {
    # Additional packages
    home.packages = with pkgs; [
      wl-clipboard # Clipboard management
      rofi-rbw-script

      # Mimic the clipboard stuff in MacOS
      (pkgs.writeShellScriptBin "pbcopy" ''
        exec ${pkgs.wl-clipboard}/bin/wl-copy "$@"
      '')
      (pkgs.writeShellScriptBin "pbpaste" ''
        exec ${pkgs.wl-clipboard}/bin/wl-paste "$@"
      '')
    ];

    programs.rofi = {
      enable = true;
      package =
        /**
          Use rofi-wayland if we're on stable
        */
        if builtins.compareVersions pkgs.rofi-unwrapped.version "2.0.0" >= 0 then
          pkgs.rofi
        else
          pkgs.rofi-wayland;
      cycle = true;
      font = "monospace";
      terminal = "${lib.getExe config.programs.kitty.package}";
      theme = "Paper";
      plugins = with pkgs; [
        rofi-bluetooth
        rofi-calc
        rofi-rbw
        rofi-power-menu
      ];
    };

    home.sessionVariables = {
      ANKI_WAYLAND = "1";
    };

    # Yellow light!
    services.wlsunset = {
      enable = true;

      # Lausanne
      latitude = "46.31";
      longitude = "6.38";
    };

    # Notification system
    # services.dunst = {
    #   enable = true;
    #   settings.global.follow = "keyboard";

    #   settings.global.width = "(400, 800)";
    #   settings.global.notification_limit = 5;

    #   settings.global.font = "Monospace 12";

    #   settings.global.dmenu = "${pkgs.bemenu}/bin/bemenu";
    #   settings.global.browser = "${pkgs.firefox-wayland}/bin/firefox";

    #   settings.global.mouse_left_click = "do_action, close_current";
    #   settings.global.mouse_right_click = "close_current";
    #   settings.global.mouse_middle_click = "close_all";

    #   settings.experimental.per_monitor_dpi = "true";
    # };
  };
}
