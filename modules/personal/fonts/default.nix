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
  } // (if pkgs.stdenv.isLinux then {
    enableDefaultFonts = false;
    fontconfig = {
      defaultFonts = {
        emoji = lib.mkBefore [ "Blobmoji" ];
        serif = lib.mkBefore [ "IBM Plex Serif" "IBM Plex Sans JP" "IBM Plex Sans KR" ];
        sansSerif = lib.mkBefore [ "IBM Plex Sans" "IBM Plex Sans JP" "IBM Plex Sans KR" ];
        monospace = lib.mkBefore [ "IBM Plex Mono" ];
      };
    };
    fontDir.enable = true;
  } else { }) // (if pkgs.stdenv.isDarwin then {
    fontDir.enable = true;
  } else { });
}
