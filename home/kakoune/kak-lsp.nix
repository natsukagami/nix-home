{ config, pkgs, lib, ... }:

with lib;
let
  rev = "63ea3b33f0f8a7c5a5557555ea59c87f71804502";
  version = "r${builtins.substring 0 6 rev}";

  kak-lsp = pkgs.kak-lsp.overrideAttrs (drv: rec {
    inherit rev version;
    buildInputs = drv.buildInputs ++
      (with pkgs; lib.optional stdenv.isDarwin darwin.apple_sdk.frameworks.SystemConfiguration);
    src = pkgs.fetchFromGitHub {
      owner = "kak-lsp";
      repo = "kak-lsp";
      rev = rev;
      sha256 = "sha256-0trrqGlAdxBWs+jRhpOPMCSmnsj/2ke2JUJsW42d9E0=";
      # sha256 = lib.fakeSha256;
    };

    cargoDeps = drv.cargoDeps.overrideAttrs (lib.const {
      inherit src;
      outputHash = "sha256-LqsCM4P6aJFZRGOxZtxXvSEbBSeQcC+4WbIwtlrO3e4=";
      # outputHash = lib.fakeSha256;
    });
  });

  lspConfig =
    {
      language = {
        bash = {
          args = [ "start" ];
          command = "bash-language-server";
          filetypes = [ "sh" ];
          roots = [ ".git" ".hg" ];
        };
        c_cpp = {
          args = [ "-v=2" "-log-file=/tmp/ccls.log" ];
          command = "ccls";
          filetypes = [ "c" "cpp" ];
          roots = [ "compile_commands.json" ".cquery" ".git" ];
        };
        crystal = {
          command = "scry";
          filetypes = [ "crystal" ];
          roots = [ "shard.yml" ];
        };
        css = {
          args = [ "--stdio" ];
          command = "css-languageserver";
          filetypes = [ "css" ];
          roots = [ "package.json" ];
        };
        d = {
          command = "dls";
          filetypes = [ "d" "di" ];
          roots = [ ".git" "dub.sdl" "dub.json" ];
        };
        dart = {
          command = "dart_language_server";
          filetypes = [ "dart" ];
          roots = [ "pubspec.yaml" ".git" ];
        };
        elm = {
          args = [ "--stdio" ];
          command = "elm-language-server";
          filetypes = [ "elm" ];
          roots = [ "elm.json" ];
        };
        fsharp = {
          command = "FSharpLanguageServer";
          filetypes = [ "fsharp" ];
          roots = [ ".git" "*.fsx" ];
        };
        go = {
          command = "gopls";
          filetypes = [ "go" ];
          offset_encoding = "utf-8";
          roots = [ "Gopkg.toml" "go.mod" ".git" ".hg" ];
          settings = { gopls = { hoverKind = "SynopsisDocumentation"; semanticTokens = true; }; };
          settings_section = "gopls";
        };
        haskell = {
          args = [ "--lsp" ];
          command = "haskell-language-server-wrapper";
          filetypes = [ "haskell" ];
          roots = [ "Setup.hs" "stack.yaml" "*.cabal" "package.yaml" ];
        };
        html = {
          args = [ "--stdio" ];
          command = "html-languageserver";
          filetypes = [ "html" ];
          roots = [ "package.json" ];
        };
        javascript = {
          args = [ "lsp" ];
          command = "flow";
          filetypes = [ "javascript" ];
          roots = [ ".flowconfig" ];
        };
        json = {
          args = [ "--stdio" ];
          command = "json-languageserver";
          filetypes = [ "json" ];
          roots = [ "package.json" ];
        };
        latex = {
          command = "texlab";
          filetypes = [ "latex" ];
          roots = [ ".git" "main.tex" "all.tex" ];
          # settings_section = "texlab";
          # settings.texlab.build = {
          #   args = [ "%f" "--synctex" "--keep-logs" "--keep-intermediates" "-Zsearch-path=${config.home.homeDirectory}/texmf" "-Zshell-escape" ];
          #   executable = "tectonic";
          # };
        };
        nim = {
          command = "nimlsp";
          filetypes = [ "nim" ];
          roots = [ "*.nimble" ".git" ];
        };
        nix = {
          command = "rnix-lsp";
          filetypes = [ "nix" ];
          roots = [ "flake.nix" "shell.nix" ".git" ];
        };
        ocaml = {
          args = [ ];
          command = "ocamllsp";
          filetypes = [ "ocaml" ];
          roots = [ "Makefile" "opam" "*.opam" "dune" ".merlin" ".ocamlformat" ];
        };
        php = {
          args = [ "--stdio" ];
          command = "intelephense";
          filetypes = [ "php" ];
          roots = [ ".htaccess" "composer.json" ];
        };
        python = {
          command = "pyls";
          filetypes = [ "python" ];
          offset_encoding = "utf-8";
          roots = [ "requirements.txt" "setup.py" ".git" ".hg" ];
        };
        racket = {
          args = [ "-l" "racket-langserver" ];
          command = "racket";
          filetypes = [ "racket" ];
          roots = [ ".git" ];
        };
        reason = {
          args = [ "--stdio" ];
          command = "ocaml-language-server";
          filetypes = [ "reason" ];
          roots = [ "package.json" "Makefile" ".git" ".hg" ];
        };
        ruby = {
          args = [ "stdio" ];
          command = "solargraph";
          filetypes = [ "ruby" ];
          roots = [ "Gemfile" ];
        };
        rust = {
          args = [ ];
          command = "rust-analyzer";
          filetypes = [ "rust" ];
          roots = [ "Cargo.toml" ];
        };
      };
      semantic_scopes = {
        entity_name_function = "function";
        entity_name_namespace = "module";
        entity_name_type = "type";
        variable = "variable";
        variable_other_enummember = "variable";
      };
      server = { timeout = 1800; };
      snippet_support = false;
      verbosity = 255;
    };

  languageOption = types.submodule {
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
      type = types.derivation;
      default = kak-lsp;
    };

    enableSnippets = mkOption {
      type = types.bool;
      default = false;
      description = "Enable snippet support";
    };

    semanticScopes = mkOption {
      type = types.attrsOf types.str;
      default = lspConfig.semantic_scopes;
      description = "The semantic scopes mapping given to kak";
    };

    serverTimeout = mkOption {
      type = types.int;
      default = 1000;
      description = "Server timeout";
    };

    languages = mkOption {
      type = types.attrsOf languageOption;
      default = lspConfig.language;
      description = "The language options";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ kak-lsp ];

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
              semantic_scopes = cfg.semanticScopes;
              server.timeout = cfg.serverTimeout;
              snippet_support = cfg.enableSnippets;
              verbosity = 255;
              language = cfg.languages;
            })
          } \
          > $out
      '';
    };
  };


}
