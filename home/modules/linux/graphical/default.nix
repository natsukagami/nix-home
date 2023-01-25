{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.linux.graphical;
in
{
  imports = [ ./x11.nix ./wayland.nix ./alacritty.nix ];
  options.linux.graphical = {
    type = mkOption {
      type = types.nullOr (types.enum [ "x11" "wayland" ]);
      description = "Enable linux graphical configurations, with either 'x11' or 'wayland'";
      default = null;
    };
    wallpaper = mkOption {
      type = types.oneOf [ types.str types.path ];
      description = "Path to the wallpaper file";
      default = "";
    };
  };
  config = mkIf (cfg.type != null) {
    # Packages

    home.packages = (with pkgs; [
      ## GUI stuff
      gnome.cheese # Webcam check
      evince # PDF reader
      gparted
      pkgs.unstable.vscode
      feh
      deluge # Torrent client
      pavucontrol # PulseAudio control panel
      thunderbird

      ## CLI stuff
      dex # .desktop file management, startup
      # sct # Display color temperature
      xdg-utils # Open stuff
    ] ++ (if pkgs.stdenv.isAarch64 then [ ] else [
      mailspring
      unstable.slack
      zotero
    ]));

    nki.programs.discord.enable = pkgs.stdenv.isx86_64;

    # Cursor
    home.pointerCursor = {
      package = pkgs.numix-cursor-theme;
      name = "Numix-Cursor";
      size = 24;
    };

    # MIME set ups
    xdg.enable = true;
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/ftp" = [ "firefox.desktop" ];
      "x-scheme-handler/ftps" = [ "firefox.desktop" ];
      "x-scheme-handler/mailspring" = [ "Mailspring.desktop" ];
    };

    home.sessionVariables = {
      # Set up Java font style
      _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";
    };

    # IBus configuration
    # dconf.settings."desktop/ibus/general" = {
    #   engines-order = hm.gvariant.mkArray hm.gvariant.type.string [ "xkb:jp::jpn" "mozc-jp" "Bamboo" ];
    #   reload-engines = hm.gvariant.mkArray hm.gvariant.type.string [ "xkb:jp::jpn" "mozc-jp" "Bamboo" ];
    # };
    # dconf.settings."desktop/ibus/general/hotkey" = {
    #   triggers = hm.gvariant.mkArray hm.gvariant.type.string [ "<Super>z" ];
    # };
  };
}
