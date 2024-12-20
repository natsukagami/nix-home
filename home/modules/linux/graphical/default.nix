{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.linux.graphical;

  thunderbird = pkgs.thunderbird-128;
  vscode = with pkgs; if stdenv.isAarch64 then unstable.vscode else unstable.vscode-fhs;

  wifi-indicator = pkgs.writeScriptBin "wifi-indicator" ''
    #!/usr/bin/env fish

    set wifi_output (${lib.getExe pkgs.iw} wlan0 link | rg "SSID: (.+)" --replace '🛜 $1' | string trim)

    if test -z $wifi_output
      echo "❌ not connected"
    else
      echo $wifi_output
    end
  '';
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
      default = with pkgs; [
        librewolf
        thunderbird
        vesktop
      ];
    };
    defaults.webBrowser = mkOption {
      type = types.str;
      default = "librewolf.desktop";
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
      sublime-music # For navidrome
      # cinny-desktop
      gajim
      vivaldi
      # Audio
      qpwgraph # Pipewire graph

      unstable.zotero
      libreoffice

      mpv # for anki
      anki-bin

      # Chat stuff
      tdesktop
      whatsapp-for-linux
      slack
      zoom-us


      ## CLI stuff
      dex # .desktop file management, startup
      # sct # Display color temperature
      xdg-utils # Open stuff
      wifi-indicator
    ] ++ cfg.startup);

    nki.programs.discord.enable = pkgs.stdenv.isx86_64;
    nki.programs.discord.package = pkgs.vesktop;

    # OBS
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        input-overlay
        obs-pipewire-audio-capture
      ];
    };

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
      "application/pdf" = [ "okularApplication_pdf.desktop" ];

      # Files
      "inode/directory" = [ "dolphin.desktop" ];
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
      name = "breeze";
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
                  mkdir -p $out
                  cp $(ls -d ${pkg}/share/applications/*.desktop | head -n 1) $out/${pkg.name}.desktop
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


