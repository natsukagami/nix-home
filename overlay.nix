{
  nixpkgs,
  nixpkgs-unstable,
  ...
}@inputs:
let
  overlay-unstable = final: prev: {
    stable = import nixpkgs {
      config.allowUnfree = true;
      system = prev.stdenv.system;
    };
    unstable = import nixpkgs-unstable {
      config.allowUnfree = true;
      system = prev.stdenv.system;
    };
  };
  overlay-needs-unstable = final: prev: {
    # Typst updates really quickly.
    typst = final.unstable.typst;
    typst-lsp = final.unstable.typst-lsp;
    # Tailscale newer = better
    tailscale = final.unstable.tailscale;
    # rbw 1.14 has SSH
    rbw = final.unstable.rbw;
    # Renovate updates frequently
    renovate = final.unstable.renovate;
    # certs dumper needs 2.11.4
    traefik-certs-dumper = final.unstable.traefik-certs-dumper;
  };
  overlay-imported = final: prev: {
    # sway = prev.sway.override { sway-unwrapped = final.swayfx-unwrapped; };
    deploy-rs = inputs.deploy-rs.packages.default;
    dtth-phanpy = inputs.dtth-phanpy.packages.${final.stdenv.system}.default;
    matrix-conduit = inputs.conduit.packages.${final.stdenv.system}.default;
    youmubot = inputs.youmubot.packages.${final.stdenv.system}.youmubot;

    # A list of source-style inputs.
    nki.sources = final.lib.attrsets.filterAttrs (name: f: !(builtins.hasAttr "outputs" f)) inputs;
  };

  overlay-versioning = final: prev: {
    kakoune-unwrapped = prev.kakoune-unwrapped.overrideAttrs (attrs: {
      version = "r${builtins.substring 0 6 inputs.kakoune.rev}";
      src = inputs.kakoune;
      patches = [
        # patches in the original package was already applied
      ];
    });

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

    kakoune-lsp = final.unstable.rustPlatform.buildRustPackage {
      name = "kakoune-lsp";
      src = inputs.kak-lsp;
      cargoLock.lockFile = "${inputs.kak-lsp}/Cargo.lock";
      buildInputs = [ final.libiconv ];

      # Upstream 2c44d28 (in v21.0.1+) reverted #704: `save: {}` is read as
      # "server doesn't want didSave" instead of "notify me, without the text",
      # so rust-analyzer never gets textDocument/didSave and never runs
      # cargo check. Drop once upstream fixes it.
      patches = [
        ./packages/common/nki-kakoune/didsave.patch
      ];

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
    };

    noto-fonts-emoji-blob-bin = prev.noto-fonts-emoji-blob-bin.overrideAttrs (
      finalAttrs: prevAttrs: {
        version = "17r1";
        src = final.fetchurl {
          name = "Blobmoji.ttf";
          url = "https://github.com/DavidBerdik/blobmoji2/releases/download/blobmoji-${finalAttrs.version}/NotoColorEmoji.ttf";
          hash = "sha256-/8dfFW9lAn1h6pdrfvYydkFAORPImBI3Gj0GT9FcZ/I=";
        };
      }
    );

    owncloud-client = prev.owncloud-client.overrideAttrs (
      finalAttrs: prevAttrs: {
        buildInputs = prevAttrs.buildInputs ++ [
          final.kdePackages.kirigami
        ];
      }
    );

    discord-canary = (
      prev.discord-canary.override {
        withVencord = true;
        useFHSEnv = false;
      }
    );

    vencord =
      let
        listenbrainz-ipc = final.fetchFromGitHub {
          owner = "qouesm";
          repo = "vencord-listenbrainz-rpc";
          rev = "2924588";
          hash = "sha256-wewGElVJot+aOwzgEy2vMOI53TpnO11KM4O3b/BJ3ew=";
        };
      in
      prev.vencord.overrideAttrs (
        finalAttrs: prevAttrs: {
          postPatch = (prevAttrs.postPatch or "") + ''
            mkdir -p src/userplugins
            cp -r ${listenbrainz-ipc} src/userplugins/listenbrainz-ipc
          '';
        }
      );

    # https://github.com/NixOS/nixpkgs/pull/559495/changes
    python314 = prev.python314.override {
      packageOverrides = finalPP: prevPP: {
        sip = prevPP.sip.overrideAttrs (
          finalAttrs: prevAttrs: {
            patches = (prevAttrs.patches or [ ]) ++ [
              # Backports pyqt5 compile failure fix from upstream
              # https://github.com/Python-SIP/sip/issues/114
              (final.fetchpatch {
                name = "legacy-api-binding-fix.patch";
                url = "https://github.com/Python-SIP/sip/commit/09598895c607f3e41f0249ade217ace0a4da6437.patch";
                hash = "sha256-v0YeHyg0ymB0v32gpVRbMBIUk9U2etjs93VuOGPGg2M=";
              })
            ];
          }
        );
      };
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
