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
    # Tailscale newer = better
    tailscale = final.unstable.tailscale;
    # rbw 1.14 has SSH
    rbw = final.unstable.rbw;
    # Renovate updates frequently
    renovate = final.unstable.renovate;
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

    tailscale = prev.tailscale.overrideAttrs (oa: {
      doCheck = false;
    }); # until new kernel is applied

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

    luminance = prev.luminance.overrideAttrs (attrs: {
      nativeBuildInputs = attrs.nativeBuildInputs ++ [ final.wrapGAppsHook3 ];
      buildInputs = attrs.buildInputs ++ [ final.glib ];
      postInstall = attrs.postInstall + ''
        glib-compile-schemas $out/share/glib-2.0/schemas
      '';
    });

    discord-canary = prev.discord-canary.overrideAttrs (attrs:
    # if final.lib.hasInfix "NIXOS_OZONE_WL" prevAttrs.installPhase then
    {
      installPhase =
        builtins.replaceStrings
          [ "NIXOS_OZONE_WL" "--enable-wayland-ime=true" ]
          [ "WAYLAND_DISPLAY" "--enable-wayland-ime=true --wayland-text-input-version=3" ]
          attrs.installPhase;
    }
    # else
    #   { }
    );

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

    rbw = final.unstable.rbw;

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

    monkeysAudio = prev.monkeysAudio.overrideAttrs (
      finalAttrs: prevAttrs: {
        version = "11.86";
        src = final.fetchzip {
          url = "https://monkeysaudio.com/files/MAC_${builtins.concatStringsSep "" (final.lib.strings.splitString "." finalAttrs.version)}_SDK.zip";
          hash = "sha256-YFw8TC38Nmdy37Bzo6p43+Ykt9fmvtAcJmZubsFqJHE=";
          stripRoot = false;
        };
      }
    );

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
