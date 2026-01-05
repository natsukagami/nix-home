{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
{
  imports = [ ./mounting.nix ];
  # Fonts
  config.fonts = {
    packages =
      with pkgs;
      mkForce [
        noto-fonts-emoji-blob-bin
        ibm-plex
        plemoljp # IBM Plex + Mono JP
        nerd-fonts.symbols-only
        noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-cjk-serif
        merriweather
        corefonts
        font-awesome_5
        font-awesome
        hack-font # for Plasma
      ];
  }
  // (
    if pkgs.stdenv.isLinux then
      {
        enableDefaultPackages = false;
        fontconfig = {
          defaultFonts = {
            emoji = lib.mkBefore [ "Blobmoji" ];
            serif = lib.mkBefore [
              "IBM Plex Serif"
              "IBM Plex Sans JP"
              "IBM Plex Sans KR"
              "Blobmoji"
            ];
            sansSerif = lib.mkBefore [
              "IBM Plex Sans"
              "IBM Plex Sans JP"
              "IBM Plex Sans KR"
              "Blobmoji"
            ];
            monospace = lib.mkBefore [
              "PlemolJP35"
              "IBM Plex Mono"
              "Font Awesome 7 Free"
              "Font Awesome 6 Free"
              "Font Awesome 5 Free"
              "Symbols Nerd Font"
              "Blobmoji"
              "IBM Plex Sans JP"
            ];
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
              <match target="pattern">
                <test qual="any" name="family" compare="eq"><string>Noto Sans</string></test>
                <edit name="family" mode="prepend" binding="strong"><string>IBM Plex Sans JP</string></edit>
                <edit name="family" mode="prepend" binding="strong"><string>IBM Plex Sans</string></edit>
              </match>
              <!-- Default font (no fc-match pattern) -->
              <match>
                <edit mode="prepend" name="family">
                  <string>IBM Plex Sans</string>
                </edit>
              </match>
              <!-- Default font for the ja_JP locale (no fc-match pattern) -->
              <match>
                <test compare="contains" name="lang">
                  <string>ja</string>
                </test>
                <edit mode="prepend" name="family">
                  <string>IBM Plex Sans JP</string>
                </edit>
              </match>
            </fontconfig>
          '';
        };
        fontDir.enable = true;
      }
    else
      { }
  )
  // (
    if pkgs.stdenv.isDarwin then
      {
        fontDir.enable = true;
      }
    else
      { }
  );
}
