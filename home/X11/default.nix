{ pkgs, config, lib, ... } :

{
    imports = [ ./packages.nix ];

    home.sessionVariables = {
        # Set up Java font style
        _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";
    };

    # X Session settings
    xsession.enable = true;

    # Wallpaper
    home.file.wallpaper = {
        source = ./. + "/wallpaper.jpg";
        target = "wallpaper.jpg";
    };

    # Cursor
    xsession.pointerCursor = {
        package = pkgs.numix-cursor-theme;
        name = "Numix-Cursor-Light";
        size = 32;
    };

    # MIME set ups
    xdg.enable = true;
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/ftp" = [ "firefox.desktop" ];
        "x-scheme-handler/ftps" = [ "firefox.desktop" ];
        "x-scheme-handler/mailspring" = [ "Mailspring.desktop" ];
    };

    # Mimic the clipboard stuff in MacOS
    home.packages = [
      (pkgs.writeShellScriptBin "pbcopy" ''
        exec ${pkgs.xsel}/bin/xsel -ib
      '')
      (pkgs.writeShellScriptBin "pbpaste" ''
        exec ${pkgs.xsel}/bin/xsel -ob
      '')
    ];
}
