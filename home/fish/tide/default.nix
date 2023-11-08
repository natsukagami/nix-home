{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.programs.fish.tide;
in
{
  options.programs.fish.tide = {
    enable = mkEnableOption "Enable tide integrations for fish";
    items = mkOption {
      type = types.attrsOf types.str;
      description = "Additional item definitions to create";
      default = { };
    };
    rightItems = mkOption {
      type = types.listOf types.str;
      description = "The list of right-items, note that `time` is not included here and will always appear last";
      default = [
        "status"
        "cmd_duration"
        "jobs"
        "direnv"
        "node"
        "python"
        "rustc"
        "java"
        "php"
        "pulumi"
        "ruby"
        "go"
        "gcloud"
        "kubectl"
        "distrobox"
        "toolbox"
        "terraform"
        "aws"
        "crystal"
        "elixir"
        "nix_shell"
      ];
    };
    leftItems = mkOption {
      type = types.listOf types.str;
      description = "The list of left-items. Note that `newline` and `character` is not included here and will always appear last";
      default = [ "os" "context" "pwd" "git" ];
    };
  };

  config.programs.fish =
    let
      tideItems = attrsets.mapAttrs' (name: def: { name = "_tide_item_${name}"; value = def; });
    in
    mkIf cfg.enable {
      functions = tideItems ({
        nix_shell = ''
          # In a Nix Shell
          if test -f $DIRENV_FILE && rg -q "^use flake" $DIRENV_FILE
            set -U tide_nix_shell_color "FFA500"
            set -U tide_nix_shell_bg_color normal
            _tide_print_item nix_shell "❄"
          end
        '';
      } // cfg.items);
      shellInit = ''
        # Configure tide items
        set -U tide_left_prompt_items ${concatMapStringsSep " " escapeShellArg cfg.leftItems} newline character
        set -U tide_right_prompt_items ${concatMapStringsSep " " escapeShellArg cfg.rightItems} time
      '';
      plugins = [
        {
          name = "tide";
          src = pkgs.fetchFromGitHub {
            owner = "IlanCosman";
            repo = "tide";
            rev = "v6.0.1";
            # sha256 = lib.fakeSha256;
            sha256 = "sha256-oLD7gYFCIeIzBeAW1j62z5FnzWAp3xSfxxe7kBtTLgA=";
          };
        }
      ];
    };
}
