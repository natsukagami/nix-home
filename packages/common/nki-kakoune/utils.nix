{ lib, writeFile, ... }: {
  mkFacesScript = name: faces: writeFile "${name}-faces.kak" (
    lib.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (name: face: "face global ${name} \"${face}\"") faces))
  );
}
