{ pkgs, config, lib, ... }:

{
  imports = [
    # Common configuration
    ./common.nix
    # We use our own firefox
    ./firefox.nix
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
    python
    zip
    # TeX
    texlive.combined.scheme-full

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
  # Keyboard options
  wayland.windowManager.sway.config.input."type:keyboard".xkb_layout = "jp";
  # 144hz adaptive refresh ON!
  wayland.windowManager.sway.config.output."ViewSonic Corporation XG2402 SERIES V4K182501054" = {
    mode = "1920x1080@144Hz";
    adaptive_sync = "on";
  };
  wayland.windowManager.sway.config.output."Unknown 24G2W1G4 ATNN21A005410" = {
    mode = "1920x1080@144Hz";
    adaptive_sync = "on";
  };
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

  # OwnCloud
  services.owncloud-client.enable = true;


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

