{ pkgs, config, lib, ... }:

{
  imports = [
    # Common configuration
    ./common.nix
    # We use our own firefox
    # ./firefox.nix
    # osu!
    # ./osu.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "nki";
  home.homeDirectory = "/home/nki";

  # More packages
  home.packages = (with pkgs; [
    # CLI stuff
    python3
    zip
    # TeX
    texlive.combined.scheme-full

    # Java & sbt
    openjdk11
    sbt
  ]);

  # Graphical set up
  linux.graphical.type = "wayland";
  linux.graphical.wallpaper = ./images/wallpaper_0.png;
  linux.graphical.defaults.webBrowser = "librewolf.desktop";
  # Enable sway
  programs.my-sway.enable = true;
  programs.my-sway.fontSize = 14.0;
  programs.my-sway.terminal = "${config.programs.kitty.package}/bin/kitty";
  programs.my-sway.browser = "librewolf";
  # Keyboard support
  wayland.windowManager.sway.config = {
    input."*".xkb_layout = "jp";
    input."1278:34:HHKB-Hybrid_3_Keyboard".xkb_layout = "jp";
    input."1:1:AT_Translated_Set_2_keyboard" = {
      xkb_options = "ctrl:swapcaps";
      # xkb_layout = "us";
    };
  };
  # input-remapping
  xdg.configFile."autostart/input-remapper-autoload.desktop".source =
    "${pkgs.input-remapper}/share/applications/input-remapper-autoload.desktop";
  # Kitty
  nki.programs.kitty = {
    enable = true;
    fontSize = 16;
  };

  # Multiple screen setup
  # services.kanshi = {
  #   enable = true;
  #   profiles.undocked.outputs = [{ criteria = "LVDS-1"; }];
  #   profiles.docked-hdmi.outputs = [
  #     # { criteria = "LVDS-1"; status = "disable"; }
  #     { criteria = "HDMI-A-1"; }
  #   ];
  # };

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

