{ config, pkgs, lib, ... }:

with lib;
let
  lspConfig =
    {
      language_ids = {
        c = "c_cpp";
        cpp = "c_cpp";
        javascript = "javascriptreact";
        typescript = "typescriptreact";
        protobuf = "proto";
        sh = "shellscript";
      };

      language_servers = {
        ccls = {
          args = [ "-v=2" "-log-file=/tmp/ccls.log" ];
          command = "ccls";
          filetypes = [ "c" "cpp" ];
          roots = [ "compile_commands.json" ".cquery" ".git" ];
        };
        gopls = {
          command = "gopls";
          filetypes = [ "go" ];
          offset_encoding = "utf-8";
          roots = [ "Gopkg.toml" "go.mod" ".git" ".hg" ];
          settings = { gopls = { hoverKind = "SynopsisDocumentation"; semanticTokens = true; }; };
          settings_section = "gopls";
        };
        haskell-language-server = {
          args = [ "--lsp" ];
          command = "haskell-language-server-wrapper";
          filetypes = [ "haskell" ];
          roots = [ "Setup.hs" "stack.yaml" "*.cabal" "package.yaml" ];
          settings_section = "haskell";
        };
        texlab = {
          command = "texlab";
          filetypes = [ "latex" ];
          roots = [ ".git" "main.tex" "all.tex" ];
          settings_section = "texlab";
          settings.texlab = {
            build.executable = "latexmk";
            build.args = [ "-pdf" "-shell-escape" "-interaction=nonstopmode" "-synctex=1" "%f" ];

            build.forwardSearchAfter = true;
            build.onSave = true;

            forwardSearch = {
              executable = "/Applications/Skim.app/Contents/SharedSupport/displayline";
              args = [ "-r" "-g" "%l" "%p" "%f" ];
            };
          };
        };
        nil = {
          command = "${pkgs.nil}/bin/nil";
          filetypes = [ "nix" ];
          roots = [ "flake.nix" "shell.nix" ".git" ];
          settings.nil = {
            formatting.command = [ "${getExe pkgs.nixpkgs-fmt}" ];
          };
        };
        pyls = {
          command = "pyls";
          filetypes = [ "python" ];
          offset_encoding = "utf-8";
          roots = [ "requirements.txt" "setup.py" ".git" ".hg" ];
        };
        rust-analyzer = {
          args = [ ];
          command = "rust-analyzer";
          filetypes = [ "rust" ];
          roots = [ "Cargo.toml" ];
        };
      };
      semantic_tokens.faces = [
        ## Items
        # (Rust) Macros
        { face = "attribute"; token = "attribute"; }
        { face = "attribute"; token = "derive"; }
        { face = "macro"; token = "macro"; } # Function-like Macro
        # Keyword and Fixed Tokens
        { face = "keyword"; token = "keyword"; }
        { face = "operator"; token = "operator"; }
        # Functions and Methods
        { face = "function"; token = "function"; }
        { face = "method"; token = "method"; }
        # Constants
        { face = "string"; token = "string"; }
        { face = "format_specifier"; token = "formatSpecifier"; }
        # Variables
        { face = "variable"; token = "variable"; modifiers = [ "readonly" ]; }
        { face = "mutable_variable"; token = "variable"; }
        { face = "module"; token = "namespace"; }
        { face = "variable"; token = "type_parameter"; }
        { face = "class"; token = "enum"; }
        { face = "class"; token = "struct"; }
        { face = "class"; token = "trait"; }
        { face = "class"; token = "union"; }
        { face = "class"; token = "class"; }

        ## Comments
        { face = "documentation"; token = "comment"; modifiers = [ "documentation" ]; }
        { face = "comment"; token = "comment"; }
      ];
      server = { timeout = 1800; };
      snippet_support = false;
      verbosity = 255;
    };

  languageServerOption = types.submodule {
    options = {
      filetypes = mkOption {
        type = types.listOf types.str;
        description = "The list of filetypes to assign the language to";
      };
      roots = mkOption {
        type = types.listOf types.str;
        description = "The list of root filenames that are used to determine the project root";
      };
      command = mkOption {
        type = types.str;
        description = "The LSP server command to be called.";
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "The arguments passed onto the LSP server.";
      };
      offset_encoding = mkOption {
        type = types.nullOr (types.enum [ "utf-8" ]);
        default = null;
        description = "The offset encoding used by the LSP server.";
      };
      settings_section = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The settings section to be sent to LSP server.";
      };
      settings = mkOption {
        type = types.nullOr (types.attrsOf types.anything);
        default = null;
        description = "Additional settings to be passed to the LSP server.";
      };
    };
  };

  cfg = config.programs.kak-lsp;
in
{
  options.programs.kak-lsp = {
    enable = mkEnableOption "Enable kak-lsp support";

    package = mkOption {
      type = types.package;
      default = pkgs.kak-lsp;
    };

    enableSnippets = mkOption {
      type = types.bool;
      default = false;
      description = "Enable snippet support";
    };

    semanticTokens.faces = mkOption {
      type = types.listOf types.anything;
      default = lspConfig.semantic_tokens.faces;
      description = "The semantic tokens faces mapping given to kak";
    };
    semanticTokens.additionalFaces = mkOption {
      type = types.listOf types.anything;
      default = [ ];
      description = "The semantic tokens faces mapping given to kak";
    };

    serverTimeout = mkOption {
      type = types.int;
      default = 1000;
      description = "Server timeout";
    };

    languageServers = mkOption {
      type = types.attrsOf languageServerOption;
      default = { };
      description = "The language options";
    };

    languageIds = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Language IDs to be sent to the LSP";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Configurations
    xdg.configFile."kak-lsp/kak-lsp.toml" = {
      source = pkgs.runCommand "config.toml"
        {
          buildInputs = [ pkgs.yj ];
          preferLocalBuild = true;
        } ''
        yj -jt -i \
          < ${
            pkgs.writeText "config.json" (builtins.toJSON {
              semantic_tokens.faces = cfg.semanticTokens.faces ++ cfg.semanticTokens.additionalFaces;
              server.timeout = cfg.serverTimeout;
              snippet_support = cfg.enableSnippets;
              verbosity = 255;
              language_server = lspConfig.language_servers // cfg.languageServers;
              language_ids = lspConfig.language_ids // cfg.languageIds;
            })
          } \
          > $out
      '';
    };
  };
}
