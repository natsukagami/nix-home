{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.programs.my-kakoune;

  autoloadModule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the autoload script/folder. It might affect kakoune's load order.";
      };
      src = mkOption {
        type = types.path;
        description = "Path to the autoload script/folder.";
      };
      wrapAsModule = mkOption {
        type = types.bool;
        default = false;
        description = "Wrap the given source file in a `provide-module` command. Fails if the `src` is not a single file.";
      };
      activationScript = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = "Add an activation script to the module. It will be wrapped in a `hook global KakBegin .*` wrapper.";
      };
    };
  };
in
{
  imports = [ ./kak-lsp.nix ./fish-session.nix ./tree-sitter.nix ];

  options.programs.my-kakoune = {
    enable = mkEnableOption "My version of the kakoune configuration";
    package = mkOption {
      type = types.package;
      default = pkgs.kakoune;
      description = "The kakoune package to be installed";
    };
    rc = mkOption {
      type = types.lines;
      default = "";
      description = "Content of the kakrc file. A line-concatenated string";
    };
    autoload = mkOption {
      type = types.listOf autoloadModule;
      default = [ ];
      description = "Sources to autoload";
    };
    themes = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = "Themes to load";
    };

    extraFaces = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra faces to include";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile =
      let
        kakouneAutoload = { name, src, wrapAsModule ? false, activationScript ? null }:
          [
            (if !wrapAsModule then {
              name = "kak/autoload/${name}";
              value.source = src;
            } else {
              name = "kak/autoload/${name}/module.kak";
              value.text = ''
                provide-module ${name} %◍
                  ${readFile src}
                ◍
              '';
            })
          ] ++ (if activationScript == null then [ ] else [{
            name = "kak/autoload/on-load/${name}.kak";
            value.text = ''
              hook global KakBegin .* %{
                ${activationScript}
              }
            '';
          }]);

        kakouneThemes = builtins.listToAttrs (builtins.attrValues (
          builtins.mapAttrs
            (name: src: {
              name = "kak/colors/${name}.kak";
              value.source = src;
            })
            cfg.themes
        ));

        kakouneFaces =
          let
            txt = strings.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (name: face: "face global ${name} \"${face}\"") cfg.extraFaces));
          in
          pkgs.writeText "faces.kak" txt;
      in
      {
        # kakrc
        "kak/kakrc".text = ''
          ${cfg.rc}

          # Load faces
          source ${kakouneFaces}
        '';
      } //
      (builtins.listToAttrs (lib.lists.flatten (map kakouneAutoload ([
        # include the original autoload files
        {
          name = "rc";
          src = "${cfg.package}/share/kak/autoload/rc";
        }
      ] ++ cfg.autoload))))
      // kakouneThemes;
  };
}

