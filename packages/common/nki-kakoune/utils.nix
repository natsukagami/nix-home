{ lib, writeTextDir, ... }: {
  mkFacesScript = name: faces: writeTextDir "share/kak/autoload/${name}/faces.kak" ''
    hook global KakBegin .* %{
    ${lib.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (name: face: "  face global ${name} \"${face}\"") faces))}
    }
  '';
}
