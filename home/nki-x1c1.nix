{ pkgs, config, lib, ... }:

let
  iio-sway = pkgs.stdenv.mkDerivation {
    name = "iio-sway";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "okeri";
      repo = "iio-sway";
      rev = "e07477d1b2478fede1446e97424a94c80767819d";
      hash = "sha256-JGacKajslCOvd/BFfFSf7s1/hgF6rJqJ6H6xNnsuMb4=";
    };
    buildInputs = with pkgs; [ dbus ];
    nativeBuildInputs = with pkgs; [ meson ninja pkg-config ];
    meta.mainProgram = "iio-sway";
  };
in
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
  ]);

  # Graphical set up
  linux.graphical.type = "wayland";
  linux.graphical.wallpaper = ./images/wallpaper_0.png;
  linux.graphical.startup = with pkgs; [ zen-browser-bin thunderbird vesktop slack ];
  linux.graphical.defaults.webBrowser.package = pkgs.zen-browser-bin;
  linux.graphical.defaults.webBrowser.desktopFile = "zen.desktop";
  # Enable sway
  programs.my-sway.enable = true;
  programs.my-sway.fontSize = 14.0;
  wayland.windowManager.sway.config = {
    # Keyboard support
    input."*".xkb_layout = "jp";
    input."1278:34:HHKB-Hybrid_3_Keyboard".xkb_layout = "jp";
    input."1:1:AT_Translated_Set_2_keyboard" = {
      xkb_options = "ctrl:swapcaps";
    };

    # Touch and Pen
    input."1386:21338:Wacom_HID_535A_Finger".map_to_output = "eDP-1";
    input."1386:21338:Wacom_HID_535A_Pen".map_to_output = "eDP-1";

    startup = [
      # rotation
      { command = "${lib.getExe iio-sway}"; }
    ];
  };
  programs.my-niri.enable = true;
  programs.my-niri.enableLaptop = true;
  # Assign some of the workspaces to big screen
  programs.my-niri.workspaces = lib.genAttrs [ "06" "07" "08" "09" "10" ] (_: { monitor = config.common.monitors.work.name; });
  programs.niri.settings = {
    # input.keyboard.xkb.options = "ctrl:swapcaps";
    input.mouse = lib.mkForce {
      # Make M575 fast for now
      accel-profile = "adaptive";
      accel-speed = 0.4;
    };
    input.touch.map-to-output = "eDP-1";
    switch-events = with config.lib.niri.actions; {
      tablet-mode-on.action = spawn "systemctl" "--user" "kill" "--signal" "SIGUSR2" "wvkbd";
      tablet-mode-off.action = spawn "systemctl" "--user" "kill" "--signal" "SIGUSR1" "wvkbd";
    };
  };
  ## Virtual keyboard
  systemd.user.services.wvkbd = {
    Unit = {
      Description = "Wayland virtual keyboard";
    };
    Install.WantedBy = [ "waybar.service" ];
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wvkbd}/bin/wvkbd-mobintl -l simple,special,emoji --landscape-layers simple,special,emoji --hidden";
    };
  };
  wayland.windowManager.sway.extraConfig = ''
    bindswitch tablet:on exec systemctl --user kill --signal SIGUSR2 wvkbd
    bindswitch tablet:off exec systemctl --user kill --signal SIGUSR1 wvkbd
  '';

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
    settings = [
      {
        profile.name = "undocked";
        profile.outputs = [{ criteria = "eDP-1"; }];
      }
      {
        profile.name = "work-both";
        profile.outputs = [
          { criteria = "eDP-1"; position = "0,${toString (builtins.floor ((2160 / work.scale - 1200) + 1200 / 3))}"; status = "enable"; }
          { criteria = work.name; position = "1920,0"; }
        ];
      }
      {
        profile.name = "work-one";
        profile.outputs = [
          { criteria = "eDP-1"; status = "disable"; }
          { criteria = work.name; }
        ];
      }
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

