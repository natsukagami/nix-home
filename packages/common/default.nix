final: prev: {
  epfl-cups-drivers = final.callPackage ./epfl-cups-drivers { };
  ttaenc = final.callPackage ./ttaenc.nix { };
  suwako-cursors = final.callPackage ./suwako-cursors { };
}
