{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.linux.graphical;

  vscode = with pkgs; if stdenv.isAarch64 then unstable.vscode else unstable.vscode-fhs;
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
      cinnamon.nemo # File manager
      thunderbird # Email
      sublime-music # For navidrome
      cinny-desktop
      gajim
      vivaldi
      # Note taking
      logseq
      # Audio
      qpwgraph # Pipewire graph

      zotero_7
      libreoffice

      mpv # for anki
      anki-bin

      tdesktop
      whatsapp-for-linux
      obs-studio

      (librewolf.override {
        nativeMessagingHosts = with pkgs; [ kdePackages.plasma-browser-integration ];
      })

      ## CLI stuff
      dex # .desktop file management, startup
      # sct # Display color temperature
      xdg-utils # Open stuff
    ] ++ (if pkgs.stdenv.isAarch64 then [ ] else [
      gnome.cheese # Webcam check, expensive
      # Chat stuff
      slack
    ]));

    nki.programs.discord.enable = pkgs.stdenv.isx86_64;
    nki.programs.discord.package = pkgs.vesktop.overrideAttrs (attrs: {
      nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.nss_latest pkgs.makeWrapper ];
      postInstall = ''
        makeWrapper $out/bin/vesktop $out/bin/discord
      '';
    });

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
      "x-scheme-handler/mailto" = [ "thunderbird.desktop" "org.gnome.Evolution.desktop" ];
      "application/pdf" = [ "org.gnome.Evince.desktop" ];
      "text/plain" = [ "kakoune.desktop" ];

      # Other Thunderbird stuff
      "x-scheme-handler/mid" = [ "thunderbird.desktop" ];
      "x-scheme-handler/news" = [ "thunderbird.desktop" ];
      "x-scheme-handler/snews" = [ "thunderbird.desktop" ];
      "x-scheme-handler/nntp" = [ "thunderbird.desktop" ];
      "x-scheme-handler/feed" = [ "thunderbird.desktop" ];
      "application/rss+xml" = [ "thunderbird.desktop" ];
      "application/x-extension-rss" = [ "thunderbird.desktop" ];
    };
    xdg.mimeApps.defaultApplications = {
      # Email
      "x-scheme-handler/mailto" = [ "thunderbird.desktop" "org.gnome.Evolution.desktop" ];
      "x-scheme-handler/webcal" = [ "thunderbird.desktop" ];
      "x-scheme-handler/webcals" = [ "thunderbird.desktop" ];

      # Other Thunderbird stuff
      "x-scheme-handler/mid" = [ "thunderbird.desktop" ];
      "x-scheme-handler/news" = [ "thunderbird.desktop" ];
      "x-scheme-handler/snews" = [ "thunderbird.desktop" ];
      "x-scheme-handler/nntp" = [ "thunderbird.desktop" ];
      "x-scheme-handler/feed" = [ "thunderbird.desktop" ];
      "application/rss+xml" = [ "thunderbird.desktop" ];
      "application/x-extension-rss" = [ "thunderbird.desktop" ];

      # Default web browser stuff
      "text/html" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/about" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/unknown" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/http" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/https" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/ftp" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/ftps" = [ cfg.defaults.webBrowser ];
      "x-scheme-handler/file" = [ cfg.defaults.webBrowser ];

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
    gtk.font.name = "IBM Plex Sans JP";
    gtk.font.size = 10;
    gtk.iconTheme = {
      package = pkgs.kdePackages.breeze-icons;
      name = "Breeze";
    };
    gtk.theme = {
      package = pkgs.kdePackages.breeze-gtk;
      name = "Breeze";
    };
    gtk.gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk.gtk2.extraConfig = ''
      gtk-enable-animations=1
      gtk-im-module="fcitx"
      gtk-theme-name="Numix"
      gtk-primary-button-warps-slider=1
      gtk-toolbar-style=3
      gtk-menu-images=1
      gtk-button-images=1
      gtk-sound-theme-name="ocean"
      gtk-icon-theme-name="breeze"
    '';
    gtk.gtk3.extraConfig.gtk-im-module = "fcitx";
    gtk.gtk4.extraConfig.gtk-im-module = "fcitx";
    ## Qt
    qt.enable = true;
    qt.platformTheme.name = "kde";
    qt.platformTheme.package = with pkgs.kdePackages; [ plasma-integration systemsettings ];
    qt.style.package = [ pkgs.kdePackages.breeze ];
    qt.style.name = "Breeze";


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
        autoStartup = listToAttrs (map f cfg.startup);
      in
      autoStartup // {
        ## Polkit UI
        "autostart/polkit.desktop".text = ''
          ${builtins.readFile "${pkgs.pantheon.pantheon-agent-polkit}/etc/xdg/autostart/io.elementary.desktop.agent-polkit.desktop"}
          OnlyShowIn=sway;
        '';
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


