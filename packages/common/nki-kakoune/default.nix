{
  callPackage,
  kakoune,
  kakoune-unwrapped,
  nki-kak-util ? callPackage ./util.nix { },
  nki-kak-lsp ? callPackage ./lsp.nix { },
  nki-kak-rc ? callPackage ./rc.nix { },
  nki-kak-plugins ? callPackage ./plugins.nix { util = nki-kak-util; },
  nki-kak-kaktex ? callPackage ./kaktex { },
  nki-kak-themes ? callPackage ./themes.nix { },
  nki-kak-faces ? callPackage ./faces.nix { util = nki-kak-util; },
  ...
}:
(kakoune.override {
  plugins =
    nki-kak-plugins
    ++ nki-kak-themes
    ++ [
      nki-kak-kaktex
      nki-kak-faces
      nki-kak-rc
      nki-kak-lsp.plugin
    ];
}).overrideAttrs
  (attrs: {
    buildCommand = ''
      ${attrs.buildCommand or ""}
      # location of kak binary is used to find ../share/kak/autoload,
      # unless explicitly overriden with KAKOUNE_RUNTIME
      rm "$out/bin/kak"
      makeWrapper "${kakoune-unwrapped}/bin/kak" "$out/bin/kak" \
        --set KAKOUNE_RUNTIME "$out/share/kak" \
        --suffix PATH ":" "${nki-kak-lsp.extraPaths}"
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
