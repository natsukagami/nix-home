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
    # Update to v7 beforehand
    peertube =
      assert (builtins.compareVersions prev.peertube.version "7.0.1" <= 0);
      final.unstable.peertube;
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
      finalAttrs: prevAttrs:
      let
        rev = "bb9dc03351acbc763d25dfb3d241c8a88c98cb98";
      in
      {
        version = "${prevAttrs.version}-${final.lib.substring 0 6 rev}";
        src = final.fetchFromGitHub {
          inherit rev;
          owner = "go-vikunja";
          repo = "vikunja";
          hash = "sha256-1DBn+fRsDNKv3xycI6SHrCaUJ8OKdrNPLgBL25c6gWE=";
        };
        vendorHash = "sha256-IuQtMO8XrjadqvuOG5P/ObguCuyh1Gsw/Or7dtu7NI8=";
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

    rofi-wayland-unwrapped =
      assert final.lib.assertMsg
        (builtins.compareVersions prev.rofi-wayland-unwrapped.version "1.7.8+wayland1" <= 0)
        "We only need this for https://github.com/lbonn/rofi/commit/f2f22e7edc635f7e4022afcf81a411776268c1c3. Use upstream package instead";
      if prev.rofi-wayland-unwrapped.version == "1.7.8+wayland1" then
        prev.rofi-wayland-unwrapped.overrideAttrs (prev: {
          src = final.fetchFromGitHub {
            owner = "lbonn";
            repo = "rofi";
            rev = "3bec3fac59394a475d162e72d5be2fb042115274";
            fetchSubmodules = true;
            hash = "sha256-xkf5HWXvzanT9tCDHbVpgUAmQlqmrPMlnv6MbcN0k9E=";
          };
        })
      else
        prev.rofi-wayland-unwrapped;

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

    open-webui =
      assert final.lib.assertMsg (
        builtins.compareVersions prev.open-webui.version "0.6.9" == -1
      ) "open-webui >=0.6.9 is upstream, remove overlay to upgrade";
      prev.open-webui.overrideAttrs (
        afinal: aprev: {
          version = "0.6.9";
          src = final.fetchFromGitHub {
            owner = "open-webui";
            repo = "open-webui";
            rev = "v${afinal.version}";
            hash = "sha256-Eib5UpPPQHXHOBVWrsNH1eEJrF8Vx9XshGYUnnAehpM=";
          };

          makeWrapperArgs = [ "--set FRONTEND_BUILD_DIR ${afinal.passthru.frontend}/share/open-webui" ];

          passthru.frontend = aprev.passthru.frontend.overrideAttrs (
            fafinal: faprev: {
              src = afinal.src;
              version = afinal.version;
              npmDepsHash = "sha256-Vcc8ExET53EVtNUhb4JoxYIUWoQ++rVTpxUPgcZ+GNI=";
              npmDeps = final.fetchNpmDeps {
                inherit (fafinal) src;
                name = "${fafinal.pname}-${fafinal.version}-npm-deps";
                hash = fafinal.npmDepsHash;
              };
            }
          );
        }
      );

    matrix-appservice-discord = prev.matrix-appservice-discord.override {
      nodejs = final.nodejs_20; # doesn't seem to compile with nodejs 22
      mkYarnPackage = attrs: final.mkYarnPackage (attrs // { nodejs = final.nodejs_20; });
    };
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
