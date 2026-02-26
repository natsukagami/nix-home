{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  kwallet =
    { pkgs, lib, ... }:
    {
      home.packages = with pkgs; [
        kdePackages.kwallet
        kdePackages.ksshaskpass
      ];
      home.sessionVariables = {
        # https://wiki.archlinux.org/title/KDE_Wallet#Using_the_KDE_Wallet_to_store_ssh_key_passphrases
        SSH_ASKPASS = lib.getExe pkgs.kdePackages.ksshaskpass;
        SSH_ASKPASS_REQUIRE = "prefer";
      };
      # Enable this for sway
      wayland.windowManager.sway.config.startup = [
        { command = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init"; }
      ];
      # Automatic dbus activation
      xdg.dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
        [D-BUS Service]
        Name=org.freedesktop.secrets
        Exec=${pkgs.kdePackages.kwallet}/bin/kwalletd6
      '';
    };

  python = pkgs.python3.withPackages (
    p: with p; [
      websockets
      pygments
    ]
  );
in
{
  imports = [
    ./modules/monitors.nix
    ./modules/linux/graphical
    ./modules/X11/xfce4-notifyd.nix
    kwallet
  ];
  config = (
    mkIf pkgs.stdenv.isLinux {
      home.packages = with pkgs; [
        psmisc # killall and friends
        file # Query file type
        zip
        python

        pinentry-gnome3 # until pinentry-qt introduces caching
      ];

      systemd.user.startServices = "sd-switch";

      # Audio stuff!
      # services.easyeffects.enable = true;

      # Bluetooth controls
      # services.mpris-proxy.enable = true;

      # Owncloud
      # services.owncloud-client.enable = true;
      # services.owncloud-client.package = pkgs.owncloud-client.overrideAttrs (attrs: {
      #   buildInputs = attrs.buildInputs ++ [ pkgs.qt6.qtwayland ];
      # });
      # systemd.user.services.owncloud-client.Unit.After = [ "graphical-session.target" ];

      # UDisks automounter
      services.udiskie.enable = true;
    }
  );
}
