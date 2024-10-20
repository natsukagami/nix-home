{ nixpkgs, nixpkgs-unstable, ... }@inputs:
let
  overlay-unstable = final: prev: {
    stable = import nixpkgs { config.allowUnfree = true; system = prev.system; };
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
      version = "0.17.0";
      ldflags = [
        "-s"
        "-w"
        "-X main.Version=${version}"
      ];
      doCheck = false;

      web-assets = final.fetchurl {
        url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_web-assets.tar.gz";
        hash = "sha256-ASqPIf98qdnkh3j72ifQN3mWnzNCTRcUegmrStvQ08Q=";
      };
      src = final.fetchFromGitHub {
        owner = "superseriousbusiness";
        repo = "gotosocial";
        rev = "v${version}";
        hash = "sha256-uyqP3zhjcXKejGFAwZoTn2kY8IpX0QAAXNzb1VG6ve8=";
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

    swayfx-unwrapped = prev.swayfx-unwrapped.overrideAttrs (attrs: {
      patches = (attrs.patches or [ ]) ++ [
        (final.fetchurl {
          url = "https://patch-diff.githubusercontent.com/raw/WillPower3309/swayfx/pull/315.patch";
          hash = "sha256-zamOLHUjlzRs8PytPTAzEsdzgVtK+HVziHgrhwPcB+E=";
        })
      ];
    });

    librewolf = (prev.librewolf.override {
      nativeMessagingHosts = with final; [ kdePackages.plasma-browser-integration ];
    });

    # Add desktop file to premid
    premid = final.symlinkJoin {
      name = prev.premid.name;
      paths = [
        prev.premid
        (final.makeDesktopItem {
          name = prev.premid.name;
          desktopName = "PreMID";
          exec = "${final.lib.getExe prev.premid} --no-sandbox %U";
          icon = "premid";
        })
      ];
    };

    # https://github.com/NixOS/nixpkgs/issues/334822
    vulkan-validation-layers = prev.vulkan-validation-layers.overrideAttrs (attrs: {
      buildInputs = attrs.buildInputs ++ [
        final.spirv-tools
      ];
    });
  };

  overlay-libs = final: prev: {
    libs.crane = inputs.crane.mkLib final;
  };

  overlay-packages = final: prev: {
    kak-tree-sitter = final.callPackage ./packages/common/kak-tree-sitter.nix { rustPlatform = final.unstable.rustPlatform; };

    kak-lsp =
      let
        src = inputs.kak-lsp;
        cargoArtifacts = final.libs.crane.buildDepsOnly { inherit src; };
      in
      final.libs.crane.buildPackage {
        inherit src cargoArtifacts;
        buildInputs = (with final;
          lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Security SystemConfiguration CoreServices ])
        ) ++ (with final; [ libiconv ]);
      };
  };

  overlay-rust-is-dumb = final: prev: {
    # Use stable delta compiled with old Rust version
    delta = final.stable.delta;
    deepfilternet = final.stable.deepfilternet;
    harmonia = final.callPackage
      (import
        (builtins.fetchurl {
          url = "https://raw.githubusercontent.com/Mic92/nixpkgs/63f91202f5cd071187ede5e5ffc56003cb442876/pkgs/by-name/ha/harmonia/package.nix";
          sha256 = "1mz211c0bxn116ix0j5xx4wlglpbkfg7d3npw1z8hg9gc0vbj2xb";
        }))
      { };
  };
in
[
  # inputs.swayfx.inputs.scenefx.overlays.override
  # inputs.swayfx.overlays.override
  inputs.mpd-mpris.overlays.default
  inputs.rust-overlay.overlays.default
  inputs.youmubot.overlays.default

  (import ./overlays/openrazer)
  overlay-unstable
  overlay-needs-unstable
  overlay-packages
  overlay-imported
  overlay-versioning
  overlay-libs
  overlay-rust-is-dumb

  (import ./packages/common)

  # Bug fixes
] # we assign the overlay created before to the overlays of nixpkgs.

