{ nixpkgs, nixpkgs-unstable, ... }@inputs:
let
  overlay-unstable = final: prev: {
    stable = import nixpkgs {
      config.allowUnfree = true;
      system = prev.system;
    };
    unstable = import nixpkgs-unstable {
      config.allowUnfree = true;
      system = prev.system;
    };
    x86 = import nixpkgs-unstable {
      system = prev.system;
      config.allowUnsupportedSystem = true;
    };
  };
  overlay-needs-unstable = final: prev: {
    # Typst updates really quickly.
    typst = final.unstable.typst;
    typst-lsp = final.unstable.typst-lsp;
    # Use 1.7.9 until things get better.
    rofi-wayland-unwrapped =
      assert final.lib.assertMsg (
        prev.rofi-wayland-unwrapped.version == final.unstable.rofi-wayland-unwrapped.version
        || prev.rofi-wayland-unwrapped.version == "1.7.8+wayland1"
      ) "rofi-wayland-unwrapped updated, use stable version";
      final.unstable.rofi-wayland-unwrapped;
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

    input-remapper = final.unstable.input-remapper;

    kakoune-unwrapped = prev.kakoune-unwrapped.overrideAttrs (attrs: {
      version = "r${builtins.substring 0 6 inputs.kakoune.rev}";
      src = inputs.kakoune;
      patches = [
        # patches in the original package was already applied
      ];
    });

    librewolf = (
      prev.librewolf.override {
        nativeMessagingHosts = with final; [ kdePackages.plasma-browser-integration ];
      }
    );

    vikunja = prev.vikunja.overrideAttrs (
      finalAttrs: prevAttrs: {
        version = "${prevAttrs.version}-${inputs.vikunja.rev}";
        src = inputs.vikunja;
        vendorHash = "sha256-duQ/B153PAd+ow/VbiWvqbFiPeyp2qL/FzROm2/wtKM=";
        # vendorHash = final.lib.fakeHash;

        checkPhase = ''
          mage test:feature
          mage test:web
        '';
      }
    );

    luminance = prev.luminance.overrideAttrs (attrs: {
      nativeBuildInputs = attrs.nativeBuildInputs ++ [ final.wrapGAppsHook ];
      buildInputs = attrs.buildInputs ++ [ final.glib ];
      postInstall =
        attrs.postInstall
        + ''
          glib-compile-schemas $out/share/glib-2.0/schemas
        '';
    });

    vesktop = prev.vesktop.overrideAttrs (attrs: {
      postFixup =
        let
          flagToReplace =
            if final.lib.hasInfix "--enable-wayland-ime=true" attrs.postFixup then
              "--enable-wayland-ime=true"
            else
              "--enable-wayland-ime";
        in
        builtins.replaceStrings
          [ "NIXOS_OZONE_WL" flagToReplace ]
          [ "WAYLAND_DISPLAY" "${flagToReplace} --wayland-text-input-version=3" ]
          attrs.postFixup;
    });

    python312 = prev.python312.override {
      packageOverrides = pfinal: pprev: {
        langchain =
          assert final.lib.assertMsg (
            pprev.langchain.version == "0.3.25" || pprev.langchain.version == "0.3.24-fix"
          ) "Revert to 0.3.24 has been applied, remove overlay";
          pprev.langchain.overrideAttrs (
            afinal: aprev: {
              version = "0.3.24-fix";
              src = final.fetchFromGitHub {
                owner = "langchain-ai";
                repo = "langchain";
                tag = "langchain==${afinal.version}";
                hash = "sha256-Up/pH2TxLPiPO49oIa2ZlNeH3TyN9sZSlNsqOIRmlxc=";
              };
            }
          );
      };
    };

    swaybg = prev.swaybg.overrideAttrs (
      finalAttrs: prevAttrs: {
        src = final.fetchFromGitHub {
          owner = "Emantor";
          repo = "swaybg";
          rev = "topic/explicit-namespace";
          hash = "sha256-u+K1+1l9JXp3xu3yqy9AnhMlqCLk7EIY5O2HawaHCQ8=";
        };
      }
    );
  };

  overlay-libs = final: prev: {
    libs.crane = inputs.crane.mkLib final;
  };

  overlay-packages = final: prev: {
    kak-tree-sitter = final.callPackage ./packages/common/kak-tree-sitter {
      rustPlatform = final.unstable.rustPlatform;
    };

    kak-lsp = final.unstable.rustPlatform.buildRustPackage {
      name = "kak-lsp";
      src = inputs.kak-lsp;
      cargoLock.lockFile = "${inputs.kak-lsp}/Cargo.lock";
      buildInputs = [ final.libiconv ];

      meta.mainProgram = "kak-lsp";
    };

    zen-browser-bin = inputs.zen-browser.packages.${final.stdenv.system}.zen-browser.override {
      inherit (inputs.zen-browser.packages.${final.stdenv.system}) zen-browser-unwrapped;
      wrapFirefox =
        opts:
        final.wrapFirefox (
          opts
          // {
            nativeMessagingHosts = with final; [ kdePackages.plasma-browser-integration ];
          }
        );
      # zen-browser-unwrapped = final.callPackage inputs.zen-browser.packages.${final.stdenv.system}.zen-browser-unwrapped.override {
      #   sources = inputs.zen-browser.inputs;
      # };
    };

    tailwindcss-language-server = prev.tailwindcss-language-server.override {
      # Until nodejs 24 is fixed upstream (nixOS/nixpkgs#420937)
      nodejs_latest = final.nodejs_22;
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
