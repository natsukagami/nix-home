{ pkgs, config, lib, ... }:

{
  imports = [
    # Common configuration
    ./common.nix
    # We use our own firefox
    # ./firefox.nix
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
    python3
    zip
    # TeX
    texlive.combined.scheme-full
    # Note-taking
    rnote

    # Java & sbt
    jdk19
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
  wayland.windowManager.sway.config = {
    # Keyboard support
    input."*".xkb_layout = "jp";
    input."1278:34:HHKB-Hybrid_3_Keyboard".xkb_layout = "jp";
    input."1:1:AT_Translated_Set_2_keyboard" = {
      xkb_options = "ctrl:swapcaps";
    };
    input."2362:628:PIXA3854:00_093A:0274_Touchpad" = {
      drag = "enabled";
      natural_scroll = "enabled";
      tap = "enabled";
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
  services.kanshi = with config.common.monitors; {
    enable = true;
    profiles.undocked.outputs = [{
      criteria = "eDP-1";
    }];
    profiles.work-both.outputs = [
      { criteria = "eDP-1"; position = "0,${toString (builtins.floor ((2160 / work.scale - 1200) + 1200 / 3))}"; status = "enable"; }
      { criteria = work.name; position = "1920,0"; }
    ];
    profiles.work-one.outputs = [
      { criteria = "eDP-1"; status = "disable"; }
      { criteria = config.common.monitors.work.name; }
    ];
  };

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
