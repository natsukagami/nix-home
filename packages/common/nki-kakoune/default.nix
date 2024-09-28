{ callPackage, kakoune, ... }: kakoune.override {
  plugins = callPackage ./plugins.nix { }
    ++ callPackage ./themes.nix { }
    ++ [
    ./kaktex
  ];
}
