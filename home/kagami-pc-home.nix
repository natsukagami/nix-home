{ pkgs, config, lib, ... }:

{
  imports = [
    # Common configuration
    ./common.nix
    # osu!
    ./osu.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "nki";
  home.homeDirectory = "/home/nki";

  # More packages
  home.packages = (with pkgs; [
    # CLI stuff
    zip
    # TeX
    texlive.combined.scheme-full
    inkscape # for TeX svg

    # Java & sbt
    openjdk11
    sbt
  ]);

  # Enable X11 configuration
  linux.graphical.type = "wayland";
  linux.graphical.wallpaper = ./images/wallpaper_1.png;
  programs.my-sway.enable = true;
  programs.my-sway.fontSize = 15.0;
  programs.my-sway.enableLaptopBars = false;
  programs.my-sway.enableMpd = true;
  # Keyboard options
  wayland.windowManager.sway.config.input."type:keyboard".xkb_layout = "jp";
  wayland.windowManager.sway.config.input."type:pointer".accel_profile = "flat";
  # 144hz adaptive refresh ON!
  wayland.windowManager.sway.config.output =
    let
      scale = 1.5;
      top_x = builtins.ceil (3840 / scale);
      top_y = builtins.ceil (((2160 / scale) - 1080) / 2);
    in
    {
      "AOC U28G2G6B PPYP2JA000013" = {
        mode = "3840x2160@60Hz";
        scale = toString scale;
        adaptive_sync = "on";
        # render_bit_depth = "10";
        position = "0 0";
      };
      "AOC 24G2W1G4 ATNN21A005410" = {
        mode = "1920x1080@144Hz";
        adaptive_sync = "on";
        position = "${toString top_x} ${toString top_y}";
      };

      "ViewSonic Corporation XG2402 SERIES V4K182501054" = {
        mode = "1920x1080@144Hz";
        adaptive_sync = "on";
      };
    };
  nki.programs.kitty.enable = true;
  nki.programs.kitty.fontSize = 14;

  # Yellow light!
  services.wlsunset = {
    enable = true;
    # # Waterloo
    # latitude = "43.3";
    # longitude = "-80.3";

    # Lausanne
    latitude = "46.31";
    longitude = "6.38";
  };

  # mpd stuff
  services.mpd.musicDirectory = "${config.home.homeDirectory}/Music";
  services.mpd-discord-rpc.enable = true;
  services.mpd-mpris.enable = true;
  # ncmpcpp
  programs.ncmpcpp.enable = true;
  programs.ncmpcpp.bindings = [
    { key = "j"; command = "scroll_down"; }
    { key = "k"; command = "scroll_up"; }
    { key = "J"; command = [ "select_item" "scroll_down" ]; }
    { key = "K"; command = [ "select_item" "scroll_up" ]; }
  ];
  programs.ncmpcpp.settings = {
    # General
    colors_enabled = "yes";
    enable_window_title = "yes";
    main_window_color = "default";
    execute_on_song_change = "${pkgs.libnotify}/bin/notify-send 'Now Playing' \"$(${pkgs.mpc_cli}/bin/mpc --format '%title% \\n%artist%' current)\"";
    autocenter_mode = "yes";
    centered_cursor = "yes";
    user_interface = "classic";

    # Progess Bar
    progressbar_look = "━━╸";
    progressbar_color = "white";
    progressbar_elapsed_color = "green";

    # UI Visibility
    # header_visibility = "no";
    # statusbar_visibility = "no";
    # titles_visibility = "no";
    startup_screen = "playlist";
    #startup_slave_screen = "visualizer"
    locked_screen_width_part = 50;
    ask_for_locked_screen_width_part = "no";

    # UI Appearance
    now_playing_prefix = "$b$3";
    now_playing_suffix = "$/b$9";
    song_status_format = "$7%t";
    song_list_format = "$8%a - %t$R  $5%l";
    song_columns_list_format = "(3f)[green]{} (60)[magenta]{t|f:Title} (1)[]{}";
    song_library_format = "{{%a - %t} (%b)}|{%f}";
    song_window_title_format = "Music";

    # Visualizer
    visualizer_in_stereo = "no";
    visualizer_type = "ellipse";
    visualizer_fps = "60";
    visualizer_look = "●●";
    visualizer_color = "33,39,63,75,81,99,117,153,189";
  };

  services.mpris-proxy.enable = true;

  # linux.graphical.x11.hidpi = true;
  # linux.graphical.x11.enablei3 = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";
}

