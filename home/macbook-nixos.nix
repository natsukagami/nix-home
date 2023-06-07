{ pkgs, config, lib, ... }:

let
  discord = pkgs.armcord.overrideAttrs (attrs: {
    postInstall = ''
      # Wrap the startup command
      makeWrapper $out/opt/ArmCord/armcord $out/bin/armcord \
        "''${gappsWrapperArgs[@]}" \
        --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/" \
        --add-flags "--ozone-platform=wayland --enable-features=UseOzonePlatform --enable-features=WebRTCPipeWireCapturer" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath attrs.buildInputs}" \
        --suffix PATH : ${lib.makeBinPath [ pkgs.xdg-utils ]}
    '';
  });
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

  nki.programs.kitty.enable = true;
  nki.programs.kitty.fontSize = 18;
  programs.fish.shellInit = lib.mkAfter ''
    set -eg MESA_GL_VERSION_OVERRIDE
    set -eg MESA_GLSL_VERSION_OVERRIDE

    export GNOME_KEYRING_CONTROL=/run/user/1001/keyring
    export SSH_AUTH_SOCK=/run/user/1001/keyring/ssh
  '';

  # More packages
  home.packages = (with pkgs; [
    # CLI stuff
    python3
    zip
    # TeX
    texlive.combined.scheme-full
    mate.mate-terminal

    firefox-wayland

    discord

    typora

    # Java & sbt
    openjdk11
    sbt
  ]);

  # Graphical set up
  linux.graphical.type = "wayland";
  linux.graphical.wallpaper = ./images/wallpaper-macbook.jpg;
  # Enable sway
  programs.my-sway.enable = true;
  programs.my-sway.fontSize = 12.0;
  programs.my-sway.enableLaptopBars = true;
  programs.my-sway.enableMpd = false;
  programs.my-sway.discord = "${discord}/bin/armcord";
  # Keyboard options
  wayland.windowManager.sway.config.input."type:keyboard".xkb_layout = "jp";
  wayland.windowManager.sway.config.output."eDP-1" = {
    mode = "2560x1600@60Hz";
    scale = "1.5";
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
    scroll_factor = "2.5";
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
  xdg.configFile."autostart/input-remapper-autoload.desktop".source =
    "${pkgs.input-remapper}/share/applications/input-remapper-autoload.desktop";

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

