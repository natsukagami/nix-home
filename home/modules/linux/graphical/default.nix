{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.linux.graphical;

  vscode = with pkgs; if stdenv.isAarch64 then unstable.vscode else unstable.vscode-fhs;

  alwaysStartup = with pkgs; [ ];
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
    startup = mkOption {
      type = types.listOf types.package;
      description = "List of packages to include in ~/.config/autostart";
      default = [ ];
    };
    defaults.webBrowser = mkOption {
      type = types.str;
      default = "firefox.desktop";
      description = "Desktop file of the default web browser";
    };
  };
  config = mkIf (cfg.type != null) {
    # Packages

    home.packages = (with pkgs; [
      ## GUI stuff
      evince # PDF reader
      gparted
      vscode
      feh # For images?
      deluge # Torrent client
      pavucontrol # PulseAudio control panel
      firefox
      librewolf
      cinnamon.nemo # File manager
      thunderbird # Email
      sublime-music # For navidrome
      # Note taking
      obsidian
      (if pkgs.stdenv.isAarch64 then
        pkgs.hello
      else logseq.override { electron = pkgs.electron_24; /* old electron versions have trouble with touchscreens */ })

      zotero
      libreoffice

      ## CLI stuff
      dex # .desktop file management, startup
      # sct # Display color temperature
      xdg-utils # Open stuff
    ] ++ (if pkgs.stdenv.isAarch64 then [ ] else [
      gnome.cheese # Webcam check, expensive
      # Chat stuff
      unstable.slack
    ]));

    nki.programs.discord.enable = pkgs.stdenv.isx86_64;

    # Yellow light!
    services.wlsunset = {
      enable = true;

      # Lausanne
      latitude = "46.31";
      longitude = "6.38";
    };

    # Cursor
    home.pointerCursor = {
      package = pkgs.suwako-cursors;
      gtk.enable = true;
      name = "Suwako";
      size = 32;
    };

    # MIME set ups
    xdg.enable = true;
    xdg.mimeApps.enable = true;

    xdg.mimeApps.associations.added = {
      "x-scheme-handler/mailto" = [ "org.gnome.Evolution.desktop" ];
      "application/pdf" = [ "org.gnome.Evince.desktop" ];
      "text/plain" = [ "kakoune.desktop" ];
    };
    xdg.mimeApps.defaultApplications = {
      # Email
      "x-scheme-handler/mailto" = [ "org.gnome.Evolution.desktop" ];

      # Default web browser stuff
      "text/html" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/about" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/unknown" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/http" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/https" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/ftp" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/ftps" = [ cfg.defaults.webBrowser ];

      # Torrent
      "application/x-bittorrent" = [ "deluge.desktop" ];
      "x-scheme-handler/magnet" = [ "deluge.desktop" ];

      # Text
      "text/plain" = [ "kakoune.desktop" ];
      "application/pdf" = [ "org.gnome.Evince.desktop" ];

      # Files
      "inode/directory" = [ "nemo.desktop" ];
    };

    # Add one for kakoune
    xdg.desktopEntries."kakoune" = {
      name = "Kakoune";
      genericName = "Text Editor";
      exec = ''kitty --class kitty-float -o initial_window_width=150c -o initial_window_height=40c ${pkgs.writeShellScript "editor.sh" ''
        $EDITOR "$@"
      ''} %U'';
      # exec = "kakoune %U";
      terminal = false;
      mimeType = [ "text/plain" ];
    };

    # Theming
    ## GTK
    gtk.enable = true;
    gtk.cursorTheme = { inherit (config.home.pointerCursor) package name size; };
    gtk.font.name = "system-ui";
    gtk.font.size = 10;
    gtk.iconTheme = {
      package = pkgs.numix-icon-theme;
      name = "Numix";
    };
    gtk.theme = {
      package = pkgs.numix-gtk-theme;
      name = "Numix";
    };
    ## Qt
    qt.enable = true;
    qt.platformTheme = "gnome";
    qt.style.package = pkgs.adwaita-qt;
    qt.style.name = "adwaita";

    home.sessionVariables = {
      # Set up Java font style
      _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";
    };

    xdg.configFile =
      let
        f = pkg: {
          name = "autostart/${pkg.name}.desktop";
          value = {
            source =
              let
                srcFile = pkgs.runCommand "${pkg.name}-startup" { } ''
                  mkdir - p $out
                  cp $
                  (ls - d ${
                  pkg}/share/applications/*.desktop | head -n 1) $out/${pkg.name}.desktop
                '';
              in
              "${srcFile}/${pkg.name}.desktop";
          };
        };
      in
      listToAttrs (map f (cfg.startup ++ alwaysStartup));
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


