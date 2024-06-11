{ nixpkgs, nixpkgs-unstable, nur, ... }@inputs:
let
  overlay-unstable = final: prev: {
    unstable = import nixpkgs-unstable { config.allowUnfree = true; system = prev.system; };
    x86 = import nixpkgs-unstable { system = prev.system; config.allowUnsupportedSystem = true; };
  };
  overlay-needs-unstable = final: prev: {
    # Typst updates really quickly.
    typst = final.unstable.typst;
    typst-lsp = final.unstable.typst-lsp;

    # Until 0.35 is in
    kitty = final.unstable.kitty;
  };
  overlay-imported = final: prev: {
    sway = prev.sway.override { sway-unwrapped = final.swayfx-unwrapped; };
    deploy-rs = inputs.deploy-rs.packages.default;
    dtth-phanpy = inputs.dtth-phanpy.packages.${final.system}.default;
    matrix-conduit = inputs.conduit.packages.${final.system}.default;

    # A list of source-style inputs.
    sources = final.lib.attrsets.filterAttrs (name: f: !(builtins.hasAttr "outputs" f)) inputs;
  };

  overlay-versioning = final: prev: {
    gotosocial = prev.gotosocial.overrideAttrs (attrs: rec {
      version = "0.16.0-rc2";
      ldflags = [
        "-s"
        "-w"
        "-X main.Version=${version}"
      ];
      doCheck = false;

      web-assets = final.fetchurl {
        url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_web-assets.tar.gz";
        hash = "sha256-fufQP9xaaaVBrgFSunDn9/jQd6eUMXqGL7TcoQHatnI=";
      };
      src = final.fetchFromGitHub {
        owner = "superseriousbusiness";
        repo = "gotosocial";
        rev = "v${version}";
        hash = "sha256-+H4rpUgjDlCc6tEIGTzkPYktwo9aCWgXr5sln8M6DNk=";
      };
      postInstall = ''
        tar xf ${web-assets}
        mkdir -p $out/share/gotosocial
        mv web $out/share/gotosocial/
      '';
    });

    input-remapper = final.unstable.input-remapper;

    kakoune-unwrapped =
      prev.kakoune-unwrapped.overrideAttrs (attrs: {
        version = "r${builtins.substring 0 6 inputs.kakoune.rev}";
        src = inputs.kakoune;
        patches = [
          # patches in the original package was already applied
        ];
      });
  };

  overlay-libs = final: prev: {
    libs.crane = inputs.crane.lib.${prev.system};
  };

  overlay-packages = final: prev: {
    kak-tree-sitter = final.callPackage ./packages/common/kak-tree-sitter.nix { rustPlatform = final.unstable.rustPlatform; };
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
  overlay-packages
  overlay-imported
  overlay-versioning
  overlay-libs
  overlay-asahi
  overlay-aarch64-linux
  nur.overlay

  (import ./packages/common)

  inputs.mpd-mpris.overlays.default
  inputs.swayfx.overlays.default
  inputs.youmubot.overlays.default

  # Bug fixes
] # we assign the overlay created before to the overlays of nixpkgs.

