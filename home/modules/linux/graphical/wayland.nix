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
    programs.mako = {
      enable = true;
      borderRadius = 5;
    };

    # Forward wallpaper settings to sway
    programs.my-sway.wallpaper = config.linux.graphical.wallpaper;
  };
}

