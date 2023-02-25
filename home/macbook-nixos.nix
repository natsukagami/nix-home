{ pkgs, config, lib, ... }:

let
  discord = pkgs.writeShellApplication {
    name = "discord";
    runtimeInputs = with pkgs; [ nodejs pkgs.unstable.electron ];
    text = ''
      cd ~/Projects/ArmCord/ && electron --force-device-scale-factor=1.5 ts-out/main.js "$@"
    '';
  };
in
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

  # No gpu terminal renderers...
  programs.my-sway.terminal = "${pkgs.mate.mate-terminal}/bin/mate-terminal";

  # More packages
  home.packages = (with pkgs; [
    # CLI stuff
    python
    zip
    # TeX
    texlive.combined.scheme-full
    mate.mate-terminal

    firefox-wayland

    discord

    # Java & sbt
    openjdk11
    sbt
  ]);

  # Graphical set up
  linux.graphical.type = "wayland";
  linux.graphical.wallpaper = ./images/wallpaper-macbook.jpg;
  # Enable sway
  programs.my-sway.enable = true;
  programs.my-sway.fontSize = 20.0;
  programs.my-sway.enableLaptopBars = true;
  programs.my-sway.enableMpd = false;
  programs.my-sway.discord = "${discord}/bin/discord";
  # Keyboard options
  wayland.windowManager.sway.config.input."type:keyboard".xkb_layout = "jp";
  wayland.windowManager.sway.config.output."eDP-1" = {
    mode = "2560x1600@60Hz";
    scale = "1";
    subpixel = "vrgb";
  };
  wayland.windowManager.sway.config.input."1452:641:Apple_Internal_Keyboard_/_Trackpad" = {
    # Keyboard stuff
    xkb_layout = "jp";
    repeat_delay = "300";
    repeat_rate = "15";
    # Trackpad stuff
    accel_profile = "adaptive";
    drag = "enabled";
    dwt = "enabled";
    middle_emulation = "enabled";
    natural_scroll = "enabled";
    pointer_accel = "0.5";
    tap = "disabled";
  };

  # Kitty
  # nki.programs.kitty = {
  #   enable = true;
  #   fontSize = 22;
  #   enableTabs = false;
  # };

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

  home.file.".gnupg/gpg-agent.conf" = {
    text = ''
      pinentry-program ${pkgs.pinentry-gnome}/bin/pinentry-gnome3
    '';
    onChange = ''
      echo "Reloading gpg-agent"
      echo RELOADAGENT | gpg-connect-agent
    '';
  };

  # Autostart
  xdg.configFile."autostart/polkit.desktop".text = ''
    ${builtins.readFile "${pkgs.pantheon.pantheon-agent-polkit}/etc/xdg/autostart/io.elementary.desktop.agent-polkit.desktop"}
    OnlyShowIn=sway;
  '';

  # Multiple screen setup
  # services.kanshi = {
  # enable = true;
  # profiles.undocked.outputs = [{ criteria = "LVDS-1"; }];
  # profiles.docked-hdmi.outputs = [
  # { criteria = "LVDS-1"; status = "disable"; }
  # { criteria = "HDMI-A-1"; }
  # ];
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

