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
      nix-output-monitor

      pinentry-gnome

      # Java stuff
      jdk21
      sbt
    ];

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
    services.owncloud-client.package = pkgs.owncloud-client.overrideAttrs (attrs: {
      buildInputs = attrs.buildInputs ++ [ pkgs.qt6.qtwayland ];
    });

    # UDisks automounter
    services.udiskie.enable = true;
  });
}

