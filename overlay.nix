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
      version = "0.17.1";
      ldflags = [
        "-s"
        "-w"
        "-X main.Version=${version}"
      ];
      doCheck = false;

      web-assets = final.fetchurl {
        url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_web-assets.tar.gz";
        hash = "sha256-rGntLlIbgfCtdqpD7tnvAY8qwF+BpYbQWfAGMhdOTgY=";
      };
      src = final.fetchFromGitHub {
        owner = "superseriousbusiness";
        repo = "gotosocial";
        rev = "v${version}";
        hash = "sha256-oWWsCs9jgd244yzWhgLkuHp7kY0BQ8+Ay6KpuBVG+U8=";
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

    vikunja =
      builtins.seq
        (final.lib.assertMsg (prev.vikunja.version == "0.24.5") "Vikunja probably doesn't need custom versions anymore")
        (final.callPackage ./packages/common/vikunja.nix { });

    luminance = prev.luminance.overrideAttrs (attrs: {
      nativeBuildInputs = attrs.nativeBuildInputs ++ [ final.wrapGAppsHook ];
      buildInputs = attrs.buildInputs ++ [ final.glib ];
      postInstall = attrs.postInstall + ''
        glib-compile-schemas $out/share/glib-2.0/schemas
      '';
    });

    vesktop = prev.vesktop.overrideAttrs (attrs: {
      postFixup = builtins.replaceStrings [ "NIXOS_OZONE_WL" "--enable-wayland-ime=true" ] [ "WAYLAND_DISPLAY" "--enable-wayland-ime=true --wayland-text-input-version=3" ] attrs.postFixup;
    });
  };

  overlay-libs = final: prev: {
    libs.crane = inputs.crane.mkLib final;
  };

  overlay-packages = final: prev: {
    kak-tree-sitter = final.callPackage ./packages/common/kak-tree-sitter { rustPlatform = final.unstable.rustPlatform; };

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

        meta.mainProgram = "kak-lsp";
      };

    zen-browser-bin = final.callPackage inputs.zen-browser.packages.${final.stdenv.system}.zen-browser.override {
      wrap-firefox = opts: final.wrapFirefox (opts // {
        nativeMessagingHosts = with final; [ kdePackages.plasma-browser-integration ];
      });
      zen-browser-unwrapped = final.callPackage inputs.zen-browser.packages.${final.stdenv.system}.zen-browser-unwrapped.override {
        sources = inputs.zen-browser.inputs;
      };
    };
  };
in
[
  # inputs.swayfx.inputs.scenefx.overlays.override
  # inputs.swayfx.overlays.override
  inputs.mpd-mpris.overlays.default
  inputs.rust-overlay.overlays.default
  inputs.youmubot.overlays.default
  inputs.niri.overlays.niri

  overlay-unstable
  overlay-needs-unstable
  overlay-packages
  overlay-imported
  overlay-versioning
  overlay-libs

  (import ./packages/common)

  # Bug fixes
] # we assign the overlay created before to the overlays of nixpkgs.
