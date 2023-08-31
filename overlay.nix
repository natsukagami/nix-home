{ nixpkgs, nixpkgs-unstable, nur, ... }@inputs:
let
  overlay-unstable = final: prev: {
    unstable = import nixpkgs-unstable { config.allowUnfree = true; system = prev.system; };
    x86 = import nixpkgs-unstable { system = prev.system; config.allowUnsupportedSystem = true; };
  };
  overlay-needs-unstable = final: prev: {
    # override some packages that needs unstable that cannot be changed in the setup.
    nix-direnv = prev.unstable.nix-direnv;

    # Typst updates really quickly.
    typst = final.unstable.typst;
    typst-lsp = final.unstable.typst-lsp;

    # Sublime-music has a bug with playlists in 0.11.x
    sublime-music =
      if builtins.compareVersions prev.sublime-music.version "0.12" < 0
      then final.unstable.sublime-music
      else prev.sublime-music;

    # New stuff in Kanshi 1.4.0
    kanshi =
      if builtins.compareVersions prev.kanshi.version "1.4.0" < 0
      then final.callPackage final.unstable.kanshi.override { }
      else prev.kanshi;
  };
  overlay-imported = final: prev: {
    rnix-lsp = inputs.rnix-lsp.defaultPackage."${final.system}";
    sway = prev.sway.override { sway-unwrapped = final.swayfx-unwrapped; };
    deploy-rs = inputs.deploy-rs.packages.default;
    dtth-phanpy = inputs.dtth-phanpy.packages.${final.system}.default;
    matrix-conduit = inputs.conduit.packages.${final.system}.default;

    # A list of source-style inputs.
    sources = final.lib.attrsets.filterAttrs (name: f: !(builtins.hasAttr "outputs" f)) inputs;
  };

  overlay-versioning = final: prev: {
    input-remapper =
      prev.input-remapper.overrideAttrs (oldAttrs: rec {
        version = "2.0.0";
        name = "input-remapper-${version}";
        src = final.fetchFromGitHub {
          owner = "sezanzeb";
          repo = "input-remapper";
          rev = "${version}";
          sha256 = "sha256-yQRUhezzI/rz7A+s5O7NGP8DjPzzXA80gIAhhV7mc3w=";
        };
      });

    thunderbird = final.wrapThunderbird final.thunderbirdPackages.thunderbird-115 { };
  };

  overlay-libs = final: prev: {
    libs.crane = inputs.crane.lib.${prev.system};
  };

  overlay-packages = final: prev: {
    gotosocial-bin = final.callPackage ./packages/x86_64-linux/gotosocial-bin.nix { };
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

