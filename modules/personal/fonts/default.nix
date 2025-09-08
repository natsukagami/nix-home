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
        (pkgs.noto-fonts-cjk-sans or pkgs.noto-fonts-cjk)
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
