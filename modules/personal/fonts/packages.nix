# The font packages, shared between the NixOS module (./default.nix) and
# home-manager on macOS (home/mac-mini.nix).
pkgs: with pkgs; [
  noto-fonts-emoji-blob-bin
  ibm-plex
  plemoljp # IBM Plex + Mono JP
  nerd-fonts.symbols-only
  noto-fonts
  noto-fonts-cjk-sans
  noto-fonts-cjk-serif
  merriweather
  corefonts
  font-awesome_5
  font-awesome
  hack-font # for Plasma
  fantasque-sans-mono # for Ghostty
]
