{ pkgs, lib, config, ... }:

with lib;
let
  noto-fonts-emoji-blob-bin =
    let
      pname = "noto-fonts-emoji-blob-bin";
      version = "15.0";
    in
    pkgs.fetchurl {
      name = "${pname}-${version}";
      url = "https://github.com/C1710/blobmoji/releases/download/v${version}/Blobmoji.ttf";
      sha256 = "sha256-n5yVk2w9x7UVrMe0Ho6nwu1Z9E/ktjo1UHdHKStoJWc=";

      downloadToTemp = true;
      recursiveHash = true;
      postFetch = ''
        install -Dm 444 $downloadedFile $out/share/fonts/blobmoji/Blobmoji.ttf
      '';
    };
in
{
  imports = [ ./mounting.nix ];
  # Fonts
  config.fonts = {
    packages = with pkgs; [
      noto-fonts-emoji-blob-bin
      ibm-plex
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      noto-fonts
      noto-fonts-cjk
      merriweather
      corefonts
    ];
  } // (if pkgs.stdenv.isLinux then {
    enableDefaultPackages = false;
    fontconfig = {
      defaultFonts = {
        emoji = lib.mkBefore [ "Blobmoji" ];
        serif = lib.mkBefore [ "IBM Plex Serif" "IBM Plex Sans JP" "IBM Plex Sans KR" ];
        sansSerif = lib.mkBefore [ "IBM Plex Sans" "IBM Plex Sans JP" "IBM Plex Sans KR" ];
        monospace = lib.mkBefore [ "IBM Plex Mono" ];
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

