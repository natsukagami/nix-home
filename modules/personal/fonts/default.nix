{ pkgs, lib, ... }:

with lib;
{
  imports = [ ./mounting.nix ];
  # Fonts
  config.fonts = {
    packages = with pkgs; mkForce [
      noto-fonts-emoji-blob-bin
      ibm-plex
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      noto-fonts
      noto-fonts-cjk
      merriweather
      corefonts
      font-awesome
      hack-font # for Plasma
    ];
  } // (if pkgs.stdenv.isLinux then {
    enableDefaultPackages = false;
    fontconfig = {
      defaultFonts = {
        emoji = lib.mkBefore [ "Blobmoji" ];
        serif = lib.mkBefore [ "IBM Plex Serif" "IBM Plex Sans JP" "IBM Plex Sans KR" "Blobmoji" ];
        sansSerif = lib.mkBefore [ "IBM Plex Sans" "IBM Plex Sans JP" "IBM Plex Sans KR" "Blobmoji" ];
        monospace = lib.mkBefore [ "IBM Plex Mono" "Font Awesome 6 Free" "Symbols Nerd Font" "Blobmoji" "IBM Plex Sans JP" ];
      };
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <alias binding="same">
            <family>system-ui</family>
            <prefer>
              <family>IBM Plex Sans</family>
              <family>IBM Plex Sans JP</family>
              <family>IBM Plex Sans KR</family>
              <family>Blobmoji</family>
            </prefer>
          </alias>
        </fontconfig>
      '';
    };
    fontDir.enable = true;
  } else { }) // (if pkgs.stdenv.isDarwin then {
    fontDir.enable = true;
  } else { });
}

