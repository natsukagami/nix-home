{
  pkgs,
  lib,
  callPackage,
  kakoune,
  kakoune-unwrapped,
  nki-kak-util ? callPackage ./utils.nix { },
  languages ? callPackage ./languages { util = nki-kak-util; },
  nki-kak-lsp ? callPackage ./lsp.nix { overrideConfig = languages.lspConfigWrapper; },
  nki-kak-rc ? callPackage ./rc.nix { },
  nki-kak-plugins ? callPackage ./plugins.nix { util = nki-kak-util; },
  nki-kak-kaktex ? callPackage ./kaktex { },
  nki-kak-themes ? callPackage ./themes.nix { },
  nki-kak-faces ? callPackage ./faces.nix { util = nki-kak-util; },
  ...
}:
let
  modules = lib.evalModules {
    modules = [
      ./config.nix
      ./tree-sitter
    ];
    specialArgs.pkgs = pkgs;
    specialArgs.kakoune-util = nki-kak-util;
  };
  cfg = modules.config.nki-kakoune;
in
(kakoune.override {
  kakoune = kakoune-unwrapped;
  plugins =
    nki-kak-plugins
    ++ nki-kak-themes
    ++ [
      nki-kak-kaktex
      nki-kak-faces
      nki-kak-rc
      nki-kak-lsp.plugin
    ]
    ++ languages.plugins
    ++ (builtins.attrValues cfg.plugins);
}).overrideAttrs
  (attrs: {
    nativeBuildInputs = (attrs.nativeBuildInputs or [ ]);
    buildCommand = ''
      ${attrs.buildCommand or ""}
      # location of kak binary is used to find ../share/kak/autoload,
      # unless explicitly overriden with KAKOUNE_RUNTIME
      rm "$out/bin/kak"
      makeWrapper "${kakoune-unwrapped}/bin/kak" "$out/bin/kak" \
        --set KAKOUNE_RUNTIME "$out/share/kak" \
        --suffix PATH ":" "${lib.makeBinPath (nki-kak-lsp.extraPackages ++ cfg.extraPackages)}"
      ${cfg.buildPhase}
    '';

    passthru = {
      lsp = nki-kak-lsp;
      rc = nki-kak-rc;
      plugins = nki-kak-plugins;
      kaktex = nki-kak-kaktex;
      themes = nki-kak-themes;
      faces = nki-kak-faces;
      util = nki-kak-util;
    };
  })
