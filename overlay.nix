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

    vikunja =
      # builtins.seq
      # (final.lib.assertMsg (prev.vikunja.version == "0.24.5") "Vikunja probably doesn't need custom versions anymore")
      (final.callPackage ./packages/common/vikunja.nix { });

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

    rofi-wayland-unwrapped =
      assert final.lib.assertMsg
        (builtins.compareVersions prev.rofi-wayland-unwrapped.version "1.7.8+wayland1" == -1)
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

    ollama =
      assert final.lib.assertMsg (
        builtins.compareVersions prev.ollama-cuda.version "0.6.7" < 0
      ) "Remove `ollama` overlay to use upstream version";
      (prev.ollama.override { rocmGpuTargets = [ "gfx1030" ]; }).overrideAttrs (
        finalAttrs: prevAttrs: {
          version = "0.6.7";
          src = final.fetchFromGitHub {
            owner = "ollama";
            repo = "ollama";
            tag = "v${finalAttrs.version}";
            hash = "sha256-GRqvaD/tAPI9cVlVu+HmRTv5zr7oCHdSlKoFfSLJ4r4=";
            fetchSubmodules = true;
          };
          vendorHash = "sha256-t7+GLNC6mRcXq9ErxN6gGki5WWWoEcMfzRVjta4fddA=";
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
