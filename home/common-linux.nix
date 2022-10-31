{ pkgs, config, lib, ... }:
with lib; {
  imports = [
    ./modules/linux/graphical
    ./modules/X11/xfce4-notifyd.nix
  ];
  config = (mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [
      psmisc # killall and friends
      file # Query file type

      pinentry-gnome
    ] ++ (
      if pkgs.stdenv.isx86_64
      then [
        vivaldi
        mpv # for anki
        pkgs.unstable.anki-bin
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

    # Bluetooth controls
    services.mpris-proxy.enable = true;

    # Owncloud
    services.owncloud-client = {
      enable = true;
      package = pkgs.unstable.owncloud-client;
    };
  });
}

