{ nixpkgs, nixpkgs-unstable, nur, ... }@inputs: system:
let
  overlay-unstable = final: prev: {
    unstable = import nixpkgs-unstable { config.allowUnfree = true; system = prev.system; };
    unfree = import nixpkgs { config.allowUnfree = true; system = prev.system; };
    x86 = import nixpkgs-unstable { system = "${system}"; config.allowUnsupportedSystem = true; };
  };
  overlay-needs-unstable = final: prev: {
    # override some packages that needs unstable that cannot be changed in the setup.
    nix-direnv = prev.unstable.nix-direnv;
  };
  overlay-imported = final: prev: {
    rnix-lsp = inputs.rnix-lsp.defaultPackage."${system}";
  };
in
{
  nixpkgs.overlays = [
    (import ./overlays/openrazer)
    overlay-unstable
    overlay-needs-unstable
    overlay-imported
    nur.overlay

    # Bug fixes
    (import ./overlays/bugfixes/delta)
  ]; # we assign the overlay created before to the overlays of nixpkgs.
}

