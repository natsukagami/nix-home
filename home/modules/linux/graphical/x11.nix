{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.linux.graphical;
in
with lib;
{
  imports = [
    ./x11/hidpi.nix
    ./x11/i3.nix
  ];
  options.linux.graphical.hasDE = mkOption {
    type = types.bool;
    description = "When enabled, disable stuff that already comes with a DE";
    default = true;
  };
  config = mkIf (cfg.type == "x11") {
    # X Session settings
    xsession.enable = true;

    # Additional packages
    home.packages = with pkgs; [
      xsel # Clipboard management

      # Mimic the clipboard stuff in MacOS
      (pkgs.writeShellScriptBin "pbcopy" ''
        exec ${pkgs.xsel}/bin/xsel -ib
      '')
      (pkgs.writeShellScriptBin "pbpaste" ''
        exec ${pkgs.xsel}/bin/xsel -ob
      '')
    ];

    # Apply cursor settings
    home.pointerCursor.x11.enable = true;

    # Notification system
    services.X11.xfce4-notifyd.enable = !cfg.hasDE;

    # Picom: X Compositor
    services.picom = mkIf (!cfg.hasDE) {
      enable = true;
      # blur = true;
      fade = true;
      fadeDelta = 3;
      shadow = true;
    };
  };
}
