{ pkgs, config, lib, ... }:
with lib; {
  imports = [
    ./modules/linux/graphical
    ./modules/X11/xfce4-notifyd.nix
  ];
  config = (mkIf (strings.hasSuffix "linux" pkgs.system) {
    home.packages = with pkgs; [
      unfree.vivaldi
    ];

    ## Gnome-keyring
    services.gnome-keyring = {
      enable = true;
      components = [ "pkcs11" "secrets" ];
    };
    services.gpg-agent.enable = true;
    services.gpg-agent.pinentryFlavor = "curses";
    services.gpg-agent.enableSshSupport = true;

    # Git "safe-directory"
    programs.git.extraConfig.safe.directory = [
      "${config.home.homeDirectory}/.config/nixpkgs"
    ];
  });
}

