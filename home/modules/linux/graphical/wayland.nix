{ pkgs, config, lib, ... }:
let
  notificationModule = { config, pkgs, lib, ... }:
    let
      swaync = pkgs.swaynotificationcenter;
    in
    with lib; mkIf (config.linux.graphical.type == "wayland") {
      home.packages = [ swaync ];
      wayland.windowManager.sway.config = {
        startup = [
          { command = "swaync"; }
        ];
      };
      xdg.configFile = {
        "swaync/config.json" = {
          text = builtins.toJSON {
            widgets = [ "inhibitors" "title" "dnd" "mpris" "notifications" ];
            scripts = { };
          };
          onChange = "swaync-client -R";
        };
        "swaync/style.css" = {
          source = ./swaync.css;
          onChange = "swaync-client -rs";
        };
      };

      programs.my-sway.waybar = {
        extraSettings = {
          modules-right = mkAfter [ "custom/swaync" ];
          modules."custom/swaync" = {
            tooltip = false;
            format = "{icon} {}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            # exec-if = "which swaync-client";
            exec = "${swaync}/bin/swaync-client -swb";
            on-click = "${swaync}/bin/swaync-client -t -sw";
            on-click-right = "${swaync}/bin/swaync-client -d -sw";
            escape = true;
          };
        };
        extraStyle = mkAfter ''
          #custom-swaync {
              background: #F0FFFF;
              color: #000000;
          }
        '';
      };
    };
in
with lib;
{
  imports = [ notificationModule ];
  config = mkIf (config.linux.graphical.type == "wayland") {
    # Additional packages
    home.packages = with pkgs; [
      wl-clipboard # Clipboard management

      # Mimic the clipboard stuff in MacOS
      (pkgs.writeShellScriptBin "pbcopy" ''
        exec ${pkgs.wl-clipboard}/bin/wl-copy
      '')
      (pkgs.writeShellScriptBin "pbpaste" ''
        exec ${pkgs.wl-clipboard}/bin/wl-paste -n
      '')
    ];

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

    # Forward wallpaper settings to sway
    programs.my-sway.wallpaper = config.linux.graphical.wallpaper;
  };
}

