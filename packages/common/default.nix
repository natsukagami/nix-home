final: prev: {
  epfl-cups-drivers = final.callPackage ./epfl-cups-drivers { };
  ttaenc = final.callPackage ./ttaenc.nix { };
}
