{ callPackage, kakoune, ... }: kakoune.override {
  plugins = (callPackage ./plugins.nix { }).plugins;
}
