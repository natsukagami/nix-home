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
    # sway = prev.sway.override { sway-unwrapped = final.swayfx-unwrapped; };
    deploy-rs = inputs.deploy-rs.packages.default;
    dtth-phanpy = inputs.dtth-phanpy.packages.${final.system}.default;
    matrix-conduit = inputs.conduit.packages.${final.system}.default;
    youmubot = inputs.youmubot.packages.${final.system}.youmubot;

    # A list of source-style inputs.
    sources = final.lib.attrsets.filterAttrs (name: f: !(builtins.hasAttr "outputs" f)) inputs;
  };

  overlay-versioning = final: prev: {
    gotosocial = prev.gotosocial.overrideAttrs (attrs: rec {
      version = "0.18.1";
      ldflags = [
        "-s"
        "-w"
        "-X main.Version=${version}"
      ];
      doCheck = false;

      web-assets = final.fetchurl {
        url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_web-assets.tar.gz";
        hash = "sha256-5MSABLPyTbFMTno9vUDvLT9h7oQM6eNUuwD+dsHiCLo=";
      };
      src = final.fetchFromGitHub {
        owner = "superseriousbusiness";
        repo = "gotosocial";
        rev = "v${version}";
        hash = "sha256-4jV1G1HwpIST2Y27RAhJB3CoJevwuhxdzi615hj0Qv0=";
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

    librewolf = (prev.librewolf.override {
      nativeMessagingHosts = with final; [ kdePackages.plasma-browser-integration ];
    });

    vikunja =
      # builtins.seq
      # (final.lib.assertMsg (prev.vikunja.version == "0.24.5") "Vikunja probably doesn't need custom versions anymore")
      (final.callPackage ./packages/common/vikunja.nix { });

    luminance = prev.luminance.overrideAttrs (attrs: {
      nativeBuildInputs = attrs.nativeBuildInputs ++ [ final.wrapGAppsHook ];
      buildInputs = attrs.buildInputs ++ [ final.glib ];
      postInstall = attrs.postInstall + ''
        glib-compile-schemas $out/share/glib-2.0/schemas
      '';
    });

    vesktop = prev.vesktop.overrideAttrs (attrs: {
      postFixup =
        let
          flagToReplace = if final.lib.hasInfix "--enable-wayland-ime=true" attrs.postFixup then "--enable-wayland-ime=true" else "--enable-wayland-ime";
        in
        builtins.replaceStrings [ "NIXOS_OZONE_WL" flagToReplace ] [ "WAYLAND_DISPLAY" "${flagToReplace} --wayland-text-input-version=3" ] attrs.postFixup;
    });


    editline-lix =
      assert final.lib.assertMsg (final.lix.version == "2.92.0") "we only need to patch this for 2.92";
      final.editline.overrideAttrs (prev: {
        configureFlags = (prev.configureFlags or [ ]) ++ [
          # Enable SIGSTOP (Ctrl-Z) behavior.
          (final.lib.enableFeature true "sigstop")
          # Enable ANSI arrow keys.
          (final.lib.enableFeature true "arrow-keys")
          # Use termcap library to query terminal size.
          (final.lib.enableFeature true "termcap")
        ];

        propagatedBuildInputs = (prev.propagatedBuildInputs or [ ]) ++ [ final.ncurses ];
      });
  };

  overlay-libs = final: prev: {
    libs.crane = inputs.crane.mkLib final;
  };

  overlay-packages = final: prev: {
    kak-tree-sitter = final.callPackage ./packages/common/kak-tree-sitter { rustPlatform = final.unstable.rustPlatform; };

    kak-lsp = final.unstable.rustPlatform.buildRustPackage {
      name = "kak-lsp";
      src = inputs.kak-lsp;
      cargoHash = "sha256-8Y+haxC7ssN07ODZcKoDdTv0vEnKqxYseLPoQSNmWI4=";
      buildInputs = [ final.libiconv ];

      meta.mainProgram = "kak-lsp";
    };
    #   cargoArtifacts = final.libs.crane.buildDepsOnly { inherit src; };
    # in
    # final.libs.crane.buildPackage {
    #   inherit src cargoArtifacts;
    #   buildInputs = (with final;
    #     lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Security SystemConfiguration CoreServices ])
    #   ) ++ (with final; [ libiconv ]);

    #   meta.mainProgram = "kak-lsp";
    # };

    zen-browser-bin = inputs.zen-browser.packages.${final.stdenv.system}.zen-browser.override {
      inherit (inputs.zen-browser.packages.${final.stdenv.system}) zen-browser-unwrapped;
      wrapFirefox = opts: final.wrapFirefox (opts // {
        nativeMessagingHosts = with final; [ kdePackages.plasma-browser-integration ];
      });
      # zen-browser-unwrapped = final.callPackage inputs.zen-browser.packages.${final.stdenv.system}.zen-browser-unwrapped.override {
      #   sources = inputs.zen-browser.inputs;
      # };
    };
  };
in
[
  inputs.mpd-mpris.overlays.default
  inputs.rust-overlay.overlays.default
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
