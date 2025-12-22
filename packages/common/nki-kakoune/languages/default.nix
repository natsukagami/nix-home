{
  callPackage,
  lib,
  util,
  ...
}:
let

  languages = [
    (callPackage ./lean4.nix { inherit util; })
  ];

  extraPackages = lib.flatten (builtins.map (lang: lang.extraPackages or [ ]) languages);
in
{
  lspConfigWrapper =
    config:
    builtins.foldl' (cfg: lang: lib.attrsets.recursiveUpdate cfg (lang.lsp or { })) config languages;
  plugins = lib.flatten (
    builtins.map (lang: if builtins.hasAttr "plugin" lang then [ lang.plugin ] else [ ]) languages
  );
  extraPaths = lib.makeBinPath extraPackages;
}
