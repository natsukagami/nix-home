final: prev: {
  epfl-cups-drivers = final.callPackage ./epfl-cups-drivers { };
  ttaenc = final.callPackage ./ttaenc.nix { };
  suwako-cursors = final.callPackage ./suwako-cursors { };
  nki-kakoune = final.callPackage ./nki-kakoune { };
  gotosocial-dtth = final.callPackage ./gotosocial { };
  niri = final.callPackage ./niri.nix { };
}
