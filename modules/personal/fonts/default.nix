{ pkgs, lib, config, ... }:

with lib;
{
  # Fonts
  config.fonts = {
    fonts = with pkgs; [
      noto-fonts-emoji-blob-bin
      ibm-plex
      (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
      noto-fonts
      noto-fonts-cjk
      merriweather
    ];
  } // (if (strings.hasSuffix "linux" pkgs.system) then {
    enableDefaultFonts = false;
    fontconfig = {
      defaultFonts = {
        emoji = lib.mkBefore [ "Blobmoji" ];
        serif = lib.mkBefore [ "IBM Plex Serif" ];
        sansSerif = lib.mkBefore [ "IBM Plex Sans" ];
        monospace = lib.mkBefore [ "IBM Plex Mono" ];
      };
    };
  } else {}) // (if (strings.hasSuffix "darwin" pkgs.system) then {
    enableFontDir = true;
  } else {});
}