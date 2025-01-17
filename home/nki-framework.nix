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
  ]);

  # Graphical set up
  linux.graphical.type = "wayland";
  linux.graphical.wallpaper = ./images/wallpaper_0.png;
  linux.graphical.defaults.webBrowser.package = pkgs.librewolf;
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
    input."2362:628:PIXA3854:00_093A:0274_Touchpad" = {
      drag = "enabled";
      natural_scroll = "enabled";
      tap = "enabled";
    };
  };
  programs.my-niri.enable = true;
  programs.my-niri.workspaces = lib.genAttrs [ "04" "05" "06" "07" "08" "09" ] (_: {
    fixed = false;
  });
  programs.niri.settings = {
    input.keyboard.xkb.options = "ctrl:swapcaps";
  };
  programs.my-waybar.extraSettings =
    let
      change-mode = pkgs.writeScript "change-mode" ''
        #!/usr/bin/env ${lib.getExe pkgs.fish}
        set -ax PATH ${lib.getBin pkgs.power-profiles-daemon} ${lib.getBin pkgs.rofi} ${lib.getBin pkgs.ripgrep}

        set profiles (powerprofilesctl list | rg "^[ *] (\S+):" -r '$1')
        set selected_index (math (contains -i (powerprofilesctl get) $profiles) - 1)
        set new_profile (printf "%s\n" $profiles | rofi -dmenu -p "Switch to power profile" -a $selected_index)
        powerprofilesctl set $new_profile
      '';
    in
    [{
      modules."battery"."on-click" = change-mode;
    }];

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
          {
            criteria = "eDP-1";
            position = "0,${toString (builtins.floor ((2160 / work.scale - 1200) + 1200 / 3))}";
            status = "enable";
          }
          { criteria = work.name; position = "1920,0"; }
        ];
      }
      {
        profile.name = "work-one";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
      { output.criteria = config.common.monitors.work.name; }
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

