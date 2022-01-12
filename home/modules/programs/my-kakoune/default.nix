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
    };
  };
in
{
  imports = [ ./kak-lsp.nix ];

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
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file =
      let
        kakouneAutoload = { name, src }: {
          name = "kakoune/autoload/${name}";
          value = {
            source = src;
            target = ".config/kak/autoload/${name}";
          };
        };
      in
      {
        # kakrc
        ".config/kak/kakrc".text = cfg.rc;
      } //
      (builtins.listToAttrs (map kakouneAutoload ([
        # include the original autoload files
        {
          name = "rc";
          src = "${cfg.package}/share/kak/autoload";
        }
      ] ++ cfg.autoload)));
  };
}
