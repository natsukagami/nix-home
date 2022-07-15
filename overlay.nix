{ nixpkgs, nixpkgs-unstable, nur, ... }@inputs:
let
  overlay-unstable = final: prev: {
    unstable = import nixpkgs-unstable { config.allowUnfree = true; system = prev.system; };
    unfree = import nixpkgs { config.allowUnfree = true; system = prev.system; };
    x86 = import nixpkgs-unstable { system = prev.system; config.allowUnsupportedSystem = true; };
  };
  overlay-needs-unstable = final: prev: {
    # override some packages that needs unstable that cannot be changed in the setup.
    nix-direnv = prev.unstable.nix-direnv;
  };
  overlay-imported = final: prev: {
    rnix-lsp = inputs.rnix-lsp.defaultPackage."${prev.system}";

    # A list of source-style inputs.
    sources = final.lib.attrsets.filterAttrs (name: f: !(builtins.hasAttr "outputs" f)) inputs;
  };

  overlay-versioning = final: prev: { };
in
[
  (import ./overlays/openrazer)
  overlay-unstable
  overlay-needs-unstable
  overlay-imported
  overlay-versioning
  nur.overlay

  # Bug fixes
] # we assign the overlay created before to the overlays of nixpkgs.

