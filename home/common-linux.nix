{ pkgs, config, lib, ... }:
with lib; {
  imports = [
    ./modules/monitors.nix
    ./modules/linux/graphical
    ./modules/X11/xfce4-notifyd.nix
    ./modules/programs/discord.nix
  ];
  config = (mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [
      psmisc # killall and friends
      file # Query file type

      pinentry-gnome

      # Java stuff
      jdk21
      sbt
    ] ++ (
      if pkgs.stdenv.isx86_64
      then [
        vivaldi
        mpv # for anki
        pkgs.unstable.anki-bin

        tdesktop
        whatsapp-for-linux
        obs-studio
      ]
      else [ ]
    );

    ## Gnome-keyring
    services.gnome-keyring = {
      enable = true;
      components = [ "pkcs11" "secrets" "ssh" ];
    };
    # services.gpg-agent.enable = true;
    # services.gpg-agent.pinentryFlavor = "curses";
    # services.gpg-agent.enableSshSupport = true;

    # Git "safe-directory"
    programs.git.extraConfig.safe.directory = [
      "${config.home.homeDirectory}/.config/nixpkgs"
    ];

    systemd.user.startServices = "sd-switch";

    # Audio stuff!
    services.easyeffects.enable = true;

    # Bluetooth controls
    # services.mpris-proxy.enable = true;

    # Owncloud
    services.owncloud-client.enable = true;

    # UDisks automounter
    services.udiskie.enable = true;
  });
}

