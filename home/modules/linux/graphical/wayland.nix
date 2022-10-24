{ pkgs, config, lib, ... }:
with lib;
{
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
    services.dunst = {
      enable = true;
      settings.global.follow = "keyboard";

      settings.global.width = "(400, 800)";
      settings.global.notification_limit = 5;

      settings.global.font = "Monospace 12";

      settings.global.dmenu = "${pkgs.bemenu}/bin/bemenu";
      settings.global.browser = "${pkgs.firefox-wayland}/bin/firefox";

      settings.global.mouse_left_click = "do_action, close_current";
      settings.global.mouse_right_click = "close_current";
      settings.global.mouse_middle_click = "close_all";

      settings.experimental.per_monitor_dpi = "true";
    };

    # Forward wallpaper settings to sway
    programs.my-sway.wallpaper = config.linux.graphical.wallpaper;
  };
}

