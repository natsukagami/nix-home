{ pkgs, config, lib, ... } :

let
    pkgsUnstable = import <nixpkgs-unstable> {};
in
{
    home.packages = [
        # Enable the FSM font with NF variant
        (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    ];
    
    programs.alacritty = {
        enable = true;
        package = pkgsUnstable.alacritty;

        settings = {
            background_opacity = 0.95;
            font = {
                size = 14.0;
                normal.family = "Fantasque Sans Mono Nerd Font";
            };
            shell = {
                program = "/bin/sh";
                args = [ "-ic" "fish" ];
            };
            colors = {
                # Default colors
                primary.background = "0xf1f1f1";
                primary.foreground = "0x424242";

                # Normal colors
                normal.black = "0x212121";
                normal.red = "0xc30771";
                normal.green = "0x10a778";
                normal.yellow = "0xa89c14";
                normal.blue = "0x008ec4";
                normal.magenta = "0x523c79";
                normal.cyan = "0x20a5ba";
                normal.white = "0xe0e0e0";

                # Bright colors
                bright.black = "0x212121";
                bright.red = "0xfb007a";
                bright.green = "0x5fd7af";
                bright.yellow = "0xf3e430";
                bright.blue = "0x20bbfc";
                bright.magenta = "0x6855de";
                bright.cyan = "0x4fb8cc";
                bright.white = "0xf1f1f1";
            };
        };
    };
}
