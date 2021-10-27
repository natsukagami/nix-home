{ pkgs, config, lib, ... }:

let
    pkgsUnstable = import <nixpkgs-unstable> {};
    # Override nss to open links in Firefox (https://github.com/NixOS/nixpkgs/issues/78961)
    discordPkg = pkgsUnstable.discord.override { nss = pkgs.nss_latest; };
in
{
    imports = [ ./alacritty.nix ./i3.nix ];

    home.packages = (with pkgs; [
        ## GUI stuff
        gnome.cheese # Webcam check
        evince # PDF reader
        gparted
        vscode
        feh
        deluge # Torrent client
        mailspring
        discordPkg
        pavucontrol # PulseAudio control panel
        # CLI stuff
        xsel # Clipboard management
        dex # .desktop file management, startup
        sct # Display color temperature
    ]);

    # Gnome-keyring
    services.gnome-keyring.enable = true;

    # Picom: X Compositor
    services.picom = {
        enable = true;
        blur = true;
        fade = true;
        fadeDelta = 3;
        shadow = true;
    };
}
