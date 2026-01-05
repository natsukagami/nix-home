{
  config,
  options,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.programs.my-kakoune;
in
{
  imports = [
    ./fish-session.nix
  ];

  options.programs.my-kakoune = {
    enable = mkEnableOption "My version of the kakoune configuration";
    package = mkOption {
      type = types.package;
      default = pkgs.nki-kakoune;
      description = "The kakoune package to be installed";
    };
    rc = mkOption {
      type = types.lines;
      default = "";
      description = "Content of the kakrc file. A line-concatenated string";
    };
    extraFaces = mkOption {
      type = types.listOf (
        types.submodule {
          options.name = mkOption { type = types.str; };
          options.face = mkOption { type = types.str; };
        }
      );
      default = { };
      description = "Extra faces to include";
    };
    autoloadFile = mkOption {
      type = options.xdg.configFile.type;
      default = { };
      description = "Extra autoload files";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile =
      let
        kakouneFaces =
          let
            txt = strings.concatStringsSep "\n" (
              builtins.map (h: "face global ${h.name} \"${h.face}\"") cfg.extraFaces
            );
          in
          pkgs.writeText "faces.kak" txt;
      in
      {
        "kak/autoload/builtin".source = "${cfg.package}/share/kak/autoload";
        # kakrc
        "kak/kakrc".text = ''
          ${cfg.rc}

          # Load faces
          source ${kakouneFaces}
        '';
      }
      // lib.mapAttrs' (name: attrs: {
        name = "kak/autoload/${name}";
        value = attrs // {
          target = "kak/autoload/${name}";
        };
      }) cfg.autoloadFile;
    xdg.dataFile."kak".source = "${cfg.package}/share/kak";
  };
}
