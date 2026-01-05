{ lib, ... }:
with { inherit (lib) types; };
{
  options.nki-kakoune = {
    buildPhase = lib.mkOption {
      type = types.lines;
      default = "";
    };

    plugins = lib.mkOption {
      type = types.attrsOf types.package;
      default = { };
    };

    extraPackages = lib.mkOption {
      type = types.listOf types.package;
      default = [ ];
    };
  };
}
