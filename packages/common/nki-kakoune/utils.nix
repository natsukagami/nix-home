{
  lib,
  writeTextDir,
  kakouneUtils,
  symlinkJoin,
  ...
}:
with {
  inherit (kakouneUtils) buildKakounePluginFrom2Nix;
};
rec {
  mkFacesScript =
    name: faces:
    writeTextDir "share/kak/autoload/${name}/faces.kak" ''
      hook global KakBegin .* %{
      ${lib.concatStringsSep "\n" (
        builtins.attrValues (builtins.mapAttrs (name: face: "  face global ${name} \"${face}\"") faces)
      )}
      }
    '';

  toDir = name: file: writeTextDir name (builtins.readFile file);

  writeActivationScript =
    script:
    writeTextDir "on-load.kak" ''
      hook global KakBegin .* %{
        ${script}
      }
    '';

  writeModuleWrapper =
    name: script:
    writeTextDir "module.kak" ''
      provide-module ${name} %◍
        ${script}
      ◍
    '';

  kakounePlugin =
    {
      name,
      src,
      wrapAsModule ? false,
      activationScript ? null,
      ...
    }@attrs:
    let
      module = if wrapAsModule then writeModuleWrapper name (builtins.readFile src) else src;
    in
    buildKakounePluginFrom2Nix {
      pname = name;
      version = attrs.version or "latest";
      src =
        if activationScript == null then
          module
        else
          symlinkJoin {
            name = "${name}-src";
            paths = [
              module
              (writeActivationScript activationScript)
            ];
          };
    };
}
