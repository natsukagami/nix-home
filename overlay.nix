{ nixpkgs, nixpkgs-unstable, nur, ... }@inputs:
let
  overlay-unstable = final: prev: {
    unstable = import nixpkgs-unstable { config.allowUnfree = true; system = prev.system; };
    x86 = import nixpkgs-unstable { system = prev.system; config.allowUnsupportedSystem = true; };
  };
  overlay-needs-unstable = final: prev: {
    # override some packages that needs unstable that cannot be changed in the setup.
    nix-direnv = prev.unstable.nix-direnv;
  };
  overlay-imported = final: prev: {
    rnix-lsp = inputs.rnix-lsp.defaultPackage."${final.system}";
    swayfx = inputs.swayfx.packages."${final.system}".default;

    # A list of source-style inputs.
    sources = final.lib.attrsets.filterAttrs (name: f: !(builtins.hasAttr "outputs" f)) inputs;
  };

  overlay-versioning = final: prev: { };

  overlay-libs = final: prev: {
    libs.crane = inputs.crane.lib.${prev.system};
  };

  overlay-aarch64-linux = final: prev:
    let
      optionalOverride = pkg: alt:
        if prev.stdenv.isLinux && prev.stdenv.isAarch64 then alt else pkg;
    in
    {
      # See https://github.com/sharkdp/fd/issues/1085
      fd = optionalOverride prev.fd (prev.fd.overrideAttrs (attrs: {
        preBuild = ''
          export JEMALLOC_SYS_WITH_LG_PAGE=16
        '';
      }));
      # See https://www.reddit.com/r/AsahiLinux/comments/zqejue/kitty_not_working_with_mesaasahiedge/
      kitty = optionalOverride prev.kitty (final.writeShellApplication {
        name = "kitty";
        runtimeInputs = [ ];
        text = ''
          MESA_GL_VERSION_OVERRIDE=3.3 MESA_GLSL_VERSION_OVERRIDE=330 ${prev.kitty}/bin/kitty "$@"
        '';
      });
      # Zotero does not have their own aarch64-linux build
      zotero = optionalOverride prev.zotero (final.callPackage ./packages/aarch64-linux/zotero.nix { });
      # Typora for aarch64-linux only
      typora = optionalOverride
        (builtins.abort "no support for non-aarch64-linux")
        (final.callPackage ./packages/aarch64-linux/typora.nix { });
    };

  overlay-asahi = inputs.nixos-m1.overlays.default;
in
[
  (import ./overlays/openrazer)
  overlay-unstable
  overlay-needs-unstable
  overlay-imported
  overlay-versioning
  overlay-libs
  overlay-asahi
  overlay-aarch64-linux
  nur.overlay

  (import ./packages/common)

  # Bug fixes
] # we assign the overlay created before to the overlays of nixpkgs.

