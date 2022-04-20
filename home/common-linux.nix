{ pkgs, config, lib, ... }:
with lib; {
  imports = [ ./modules/linux/graphical ./modules/X11/xfce4-notifyd.nix ];
  config = (mkIf (strings.hasSuffix "linux" pkgs.system) {
    ## Gnome-keyring
    services.gnome-keyring = {
      enable = true;
      components = [ "pkcs11" "secrets" "ssh" ];
    };
    services.gpg-agent.enable = true;
    services.gpg-agent.enableSshSupport = true;
    services.gpg-agent.pinentryFlavor = "gtk2";
  });
}

