{ pkgs, lib, ... }:

let
  kak-lsp-frontend = { pkgs, lib, ... }:
    let
      langserver = name: {
        name = "vscode-${name}-language-server";
        value = {
          args = [ "--stdio" ];
          command = "vscode-${name}-language-server";
          filetypes = [ name ];
          roots = [ "package.json" ".git" ];
        };
        package = pkgs.nodePackages.vscode-langservers-extracted;
      };

      tailwind = {
        command = "tailwindcss-language-server";
        args = [ "--stdio" ];
        filetypes = [ "html" "css" "javascript" "typescript" "templ" ];
        roots = [ "tailwind.config.{js,cjs,mjs,ts}" "package.json" ".git" ];
        settings_section = "tailwindCSS";
        settings.tailwindCSS = {
          validate = "warning";
          userLanguages.templ = "html";
        };
        package = pkgs.tailwindcss-language-server;
      };

      templModule = { pkgs, lib, ... }: {
        programs.kak-lsp.languageServers."vscode-html-language-server".filetypes = [ "templ" ];
        programs.kak-lsp.languageServers."tailwindcss-language-server".filetypes = [ "templ" ];
        programs.kak-lsp.languageServers.templ = {
          command = "templ";
          args = [ "lsp" ];
          filetypes = [ "templ" ];
          roots = [ "go.mod" ".git" ];
          package = pkgs.unstable.templ;
        };

      };

    in
    {
      imports = [ templModule ];

      programs.kak-lsp.languageServers = (builtins.listToAttrs (map langserver [ "html" "css" "json" ])) // {
        tailwindcss-language-server = tailwind;
      };
    };

  ltexLsp = { pkgs, lib, ... }: {
    programs.kak-lsp.languageServers.ltex-ls = {
      command = "ltex-ls";
      args = [ "--log-file=/tmp" ];
      filetypes = [ "latex" "typst" ];
      roots = [ "main.tex" "main.typ" ".git" ];
      package = pkgs.ltex-ls;
    };
  };

in
{
  imports = [ ../modules/programs/my-kakoune ./kaktex.nix kak-lsp-frontend ltexLsp ];

  home.packages = with pkgs; [
    # ctags for peneira
    universal-ctags
    # tree-sitter for kak
    kak-tree-sitter
  ];

  # xdg.configFile."kak-tree-sitter/config.toml".source = ./kak-tree-sitter.toml;

  # Enable the kakoune package.
  programs.my-kakoune.enable = true;
  programs.my-kakoune.enable-fish-session = true;
  programs.kak-lsp.enable = true;
  programs.kak-lsp.semanticTokens.additionalFaces = [
    # Typst
    { face = "header"; token = "heading"; }
    { face = "ts_markup_link_url"; token = "link"; }
    { face = "ts_markup_link_uri"; token = "ref"; }
    { face = "ts_markup_link_label"; token = "label"; }
    { face = "ts_property"; token = "pol"; }
    { face = "ts_markup_list_checked"; token = "marker"; }
    { face = "ts_constant_builtin_boolean"; token = "bool"; }
    { face = "ts_keyword_control"; token = "delim"; }
    { face = "ts_number"; token = "text"; modifiers = [ "math" ]; }
    { face = "ts_markup_bold"; token = "text"; modifiers = [ "strong" ]; }
    { face = "ts_markup_italic"; token = "text"; modifiers = [ "emph" ]; }
  ];

  programs.kak-lsp.languageServers.elixir-ls = {
    args = [ ];
    command = "elixir-ls";
    filetypes = [ "elixir" ];
    roots = [ "mix.exs" ];
  };
  programs.kak-lsp.languageServers.typescript-language-server = {
    args = [ "--stdio" ];
    command = "typescript-language-server";
    filetypes = [ "typescript" "javascript" ];
    roots = [ "package.json" ];
    package = pkgs.nodePackages.typescript-language-server;
  };
  programs.kak-lsp.languageServers.fsautocomplete = {
    args = [ "--adaptive-lsp-server-enabled" "--project-graph-enabled" "--source-text-factory" "RoslynSourceText" ];
    command = "fsautocomplete";
    filetypes = [ "fsharp" ];
    roots = [ "*.fsproj" ];
    settings_section = "FSharp";
    settings.FSharp = {
      AutomaticWorkspaceInit = true;
    };
  };
  programs.kak-lsp.languageServers.metals = {
    command = "metals";
    filetypes = [ "scala" ];
    roots = [ "build.sbt" "build.sc" "build.mill" ];
    settings_section = "metals";
    settings.metals = {
      enableSemanticHighlighting = true;
      showInferredType = true;
      decorationProvider = true;
      inlineDecorationProvider = true;
      # From kakoune-lsp's own options
      icons = "unicode";
      isHttpEnabled = true;
      statusBarProvider = "log-message";
      compilerOptions = { overrideDefFormat = "unicode"; };
    };
    package = pkgs.metals;
  };
  programs.kak-lsp.languageServers.texlab = {
    command = "texlab";
    filetypes = [ "latex" ];
    roots = [ "main.tex" "all.tex" ".git" ];
    settings_section = "texlab";
    settings.texlab = {
      build.executable = "latexmk";
      build.args = [ "-pdf" "-shell-escape" "-interaction=nonstopmode" "-synctex=1" "%f" ];

      build.forwardSearchAfter = true;
      build.onSave = true;

      forwardSearch =
        (if pkgs.stdenv.isDarwin then {
          executable = "/Applications/Skim.app/Contents/SharedSupport/displayline";
          args = [ "-r" "-g" "%l" "%p" "%f" ];
        } else
          {
            executable = "${pkgs.zathura}/bin/zathura";
            args = [ "--synctex-forward" "%l:1:%f" "%p" "-x" "${./kaktex} jump %%{input} %%{line} %%{column}" ];
          });
    };
    package = pkgs.texlab;
  };
  programs.kak-lsp.languageServers.typst-lsp = {
    command = "typst-lsp";
    filetypes = [ "typst" ];
    roots = [ "main.typ" ".git" ];
    settings_section = "typst-lsp";
    settings.typst-lsp = {
      experimentalFormatterMode = "on";
    };
  };
  programs.kak-lsp.languageServers.marksman = {
    command = "marksman";
    filetypes = [ "markdown" ];
    roots = [ ".marksman.toml" ".git" ];
    package = pkgs.marksman;
  };
  programs.kak-lsp.languageServers.rust-analyzer = {
    args = [ ];
    command = "rust-analyzer";
    filetypes = [ "rust" ];
    roots = [ "Cargo.toml" ];
    package = pkgs.rust-analyzer;
  };

  programs.my-kakoune.tree-sitter.extraAliases = {
    # Scala stuff
    method = "function";
    module = "namespace";
    function_call = "function";
    method_call = "method";

    boolean = "constant_builtin_boolean";
    number = "constant_numeric";
    float = "constant_numeric_float";

    type_qualifier = "keyword_special";
    storageclass = "keyword_storage_modifier";
    conditional = "keyword_conditional";
    include = "keyword_control_import";
  };
  programs.my-kakoune.tree-sitter.languages =
    let
      tree-sitter-go = pkgs.fetchFromGitHub {
        owner = "tree-sitter";
        repo = "tree-sitter-go";
        rev = "v0.20.0";
        hash = "sha256-G7d8CHCyKDAb9j6ijRfHk/HlgPqSI+uvkuRIRRvjkHI=";
      };
    in
    {
      scala =
        let
          src = pkgs.fetchFromGitHub {
            owner = "tree-sitter";
            repo = "tree-sitter-scala";
            rev = "70afdd5632d57dd63a960972ab25945e353a52f6";
            hash = "sha256-bi0Lqo/Zs2Uaz1efuKAARpEDg5Hm59oUe7eSXgL1Wow=";
          };
        in
        {
          grammar.src = src;
          queries.src = src;
          queries.path = "queries/scala";
        };
      haskell =
        let
          src = pkgs.fetchFromGitHub {
            owner = "tree-sitter";
            repo = "tree-sitter-haskell";
            rev = "ba0bfb0e5d8e9e31c160d287878c6f26add3ec08";
            hash = "sha256-ZSOF0CLOn82GwU3xgvFefmh/AD2j5zz8I0t5YPwfan0=";
          };
        in
        {
          grammar.src = src;
          grammar.compile.args = [ "-c" "-fpic" "../parser.c" "../scanner.c" "../unicode.h" "-I" ".." ];
          queries.src = src;
          queries.path = "queries";
        };
      yaml = {
        grammar.src = pkgs.fetchFromGitHub {
          owner = "ikatyang";
          repo = "tree-sitter-yaml";
          rev = "0e36bed171768908f331ff7dff9d956bae016efb";
          hash = "sha256-bpiT3FraOZhJaoiFWAoVJX1O+plnIi8aXOW2LwyU23M=";
        };
        grammar.compile.args = [ "-c" "-fpic" "../scanner.cc" "../parser.c" "-I" ".." ];
        grammar.link.args = [ "-shared" "-fpic" "scanner.o" "parser.o" ];
        grammar.link.flags = [ "-O3" "-lstdc++" ];

        queries.src = pkgs.fetchFromGitHub {
          owner = "helix-editor";
          repo = "helix";
          rev = "dbd248fdfa680373d94fbc10094a160aafa0f7a7";
          hash = "sha256-wk8qVUDFXhAOi1Ibc6iBMzDCXb6t+YiWZcTd0IJybqc=";
        };
        queries.path = "runtime/queries/yaml";
      };

      templ =
        let
          src = pkgs.fetchFromGitHub {
            owner = "vrischmann";
            repo = "tree-sitter-templ";
            rev = "044ad200092170727650fa6d368df66a8da98f9d";
            hash = "sha256-hJuB3h5pp+LLfP0/7bAYH0uLVo+OQk5jpzJb3J9BNkY=";
          };
        in
        {
          grammar.src = src;
          queries.src = pkgs.runCommandLocal "templ-tree-sitter-queries" { } ''
            mkdir -p $out/queries
            # copy most stuff from tree-sitter-templ
            install -m644 ${src}/queries/templ/* $out/queries
            # override inherited files
            cat ${tree-sitter-go}/queries/highlights.scm ${src}/queries/templ/highlights.scm > $out/queries/highlights.scm
          '';
          queries.path = "queries";
        };

      go = {
        grammar.src = tree-sitter-go;
        grammar.compile.args = [ "-c" "-fpic" "../parser.c" "-I" ".." ];
        grammar.link.args = [ "-shared" "-fpic" "parser.o" ];
        queries.src = tree-sitter-go;
        queries.path = "queries";
      };

      hylo =
        let
          src = pkgs.fetchFromGitHub {
            owner = "natsukagami";
            repo = "tree-sitter-hylo";
            rev = "494cbdff0d13cbc67348316af2efa0286dbddf6f";
            hash = "sha256-R5UeoglCTl0do3VDJ/liCTeqbxU9slvmVKNRA/el2VY=";
          };
        in
        {
          grammar.src = src;
          grammar.compile.args = [ "-c" "-fpic" "../parser.c" "-I" ".." ];
          grammar.link.args = [ "-shared" "-fpic" "parser.o" ];
          queries.src = src;
          queries.path = "queries";
        };
    };

  programs.my-kakoune.package = pkgs.kakoune;
  programs.my-kakoune.rc =
    builtins.readFile ./kakrc + ''

      # Source any settings in the current working directory,
      # recursive upwards
      evaluate-commands %sh{
          ${pkgs.writeScript "source-pwd" (builtins.readFile ./source-pwd)}
      }
    '';

  programs.my-kakoune.extraFaces = {
    Default = "%opt{text},%opt{base}";
    BufferPadding = "%opt{base},%opt{base}";
    MenuForeground = "%opt{blue},white+bF";
    MenuBackground = "%opt{sky},white+F";
    Information = "%opt{sky},white";
    # Markdown help color scheme
    InfoDefault = "Information";
    InfoBlock = "@block";
    InfoBlockQuote = "+i@block";
    InfoBullet = "@bullet";
    InfoHeader = "@header";
    InfoLink = "@link";
    InfoLinkMono = "+b@mono";
    InfoMono = "@mono";
    InfoRule = "+b@Information";
    InfoDiagnosticError = "@DiagnosticError";
    InfoDiagnosticHint = "@DiagnosticHint";
    InfoDiagnosticInformation = "@Information";
    InfoDiagnosticWarning = "@DiagnosticWarning";
    # Extra faces
    macro = "+u@function";
    method = "@function";
    format_specifier = "+i@string";
    mutable_variable = "+i@variable";
    class = "+b@variable";
  };
  programs.my-kakoune.autoload = [
    # My own scripts
    {
      name = "latex.kak";
      src = ./autoload/latex.kak;
    }
    {
      name = "markdown.kak";
      src = ./autoload/markdown.kak;
    }

    # Plugins
    {
      name = "luar";
      src = pkgs.fetchFromGitHub {
        owner = "gustavo-hms";
        repo = "luar";
        rev = "2f430316f8fc4d35db6c93165e2e77dc9f3d0450";
        sha256 = "sha256-vHn/V3sfzaxaxF8OpA5jPEuPstOVwOiQrogdSGtT6X4=";
      };
      activationScript = ''
        # Enable luar
        require-module luar
        # Use luajit
        set-option global luar_interpreter ${pkgs.luajit}/bin/luajit
      '';
    }
    {
      name = "peneira";
      src = pkgs.fetchFromGitHub {
        owner = "natsukagami";
        repo = "peneira";
        rev = "743b9971472853a752475e7c070ce99089c6840c";
        sha256 = "sha256-E4ndbF9YC1p0KrvSuGgwmG1Y2IGTuGKJo/AuMixhzlM=";
      };
      activationScript = ''
        require-module peneira

        # Change selection color
        set-face global PeneiraSelected @PrimarySelection

        # Buffers list
        define-command -hidden peneira-buffers %{
            peneira 'buffers: ' %{ printf '%s\n' $kak_quoted_buflist } %{
                buffer %arg{1}
            }
        }

        # Grep in the current location
        define-command peneira-grep %{
          peneira 'line: ' "rg -n ." %{
            lua %arg{1} %{
              local file, line = arg[1]:match("([^:]+):(%d+):")
              kak.edit(file, line)
            }
          }
        }

        # A peneira menu
        declare-user-mode fuzzy-match-menu

        map -docstring "Switch to buffer"                            global fuzzy-match-menu b ": peneira-buffers<ret>"
        map -docstring "Symbols"                                     global fuzzy-match-menu s ": peneira-symbols<ret>"
        map -docstring "Lines"                                       global fuzzy-match-menu l ": peneira-lines<ret>"
        map -docstring "Lines in the current directory"              global fuzzy-match-menu g ": peneira-grep<ret>"
        map -docstring "Files in project"                            global fuzzy-match-menu f ": peneira-files<ret>"
        map -docstring "Files in currently opening file's directory" global fuzzy-match-menu F ": peneira-local-files<ret>"

        # Bind menu to user mode
        map -docstring "Fuzzy matching" global user f ": enter-user-mode fuzzy-match-menu<ret>"
      '';
    }
    {
      name = "kakoune-focus";
      src = pkgs.fetchFromGitHub {
        owner = "caksoylar";
        repo = "kakoune-focus";
        rev = "949c0557cd4c476822acfa026ca3c50f3d38a3c0";
        sha256 = "sha256-ZV7jlLJQyL420YG++iC9rq1SMjo3WO5hR9KVvJNUiCs=";
      };
      activationScript = ''
        map global user <space> ': focus-toggle<ret>' -docstring "toggle selections focus"
      '';
    }
    {
      name = "kakoune-inc-dec";
      src = pkgs.fetchFromGitLab {
        owner = "Screwtapello";
        repo = "kakoune-inc-dec";
        rev = "7bfe9c51";
        sha256 = "0f33wqxqbfygxypf348jf1fiscac161wf2xvnh8zwdd3rq5yybl0";
      };
    }
    {
      name = "racket.kak";
      src = (builtins.fetchTree {
        type = "git";
        url = "https://bitbucket.org/KJ_Duncan/kakoune-racket.kak.git";
        rev = "e397042009b46916ff089d79166ec0e8ca813a18";
        narHash = "sha256-IcxFmvG0jqpMCG/dT9crVRgPgMGKkic6xwrnW5z4+bc=";
      }) + "/rc";
    }
    # {
    #   name = "kakoune-discord";
    #   src = (builtins.getFlake "github:natsukagami/kakoune-discord/03f95e40d6efd8fd3de7bca31653d43de2dcfc5f").packages.${pkgs.system}.kakoune-discord-rc + "/rc";
    # }
    rec {
      name = "kakoune-mirror";
      src = pkgs.fetchFromGitHub
        {
          owner = "Delapouite";
          repo = "kakoune-mirror";
          rev = "5710635f440bcca914d55ff2ec1bfcba9efe0f15";
          sha256 = "sha256-uslx4zZhvjUylrPWvTOugsKYKKpF0EEz1drc1Ckrpjk=";
        } + "/mirror.kak";
      wrapAsModule = true;
      activationScript = ''
        require-module ${name}

        # Bind <a-w> to ${name}
        map global normal <a-w> ': enter-user-mode -lock mirror<ret>'
      '';
    }
    {
      name = "unicode-math";
      src = pkgs.fetchFromGitHub {
        owner = "natsukagami";
        repo = "kakoune-unicode-math";
        rev = "08dff25da2b86ee0b0777091992bc7fb28c3cb1d";
        # sha256 = lib.fakeSha256;
        sha256 = "sha256-j0L1ARex1i2ma8sGLYwgkfAbh0jWKh/6QGHFaxPXIKc=";
        fetchSubmodules = true;
      };
      activationScript = ''
        require-module unicode-math

        # Bind <c-s> to the menu
        map global insert <c-s> '<a-;>: insert-unicode '
      '';
    }
    {
      name = "kakoune-buffers";
      src = pkgs.fetchFromGitHub {
        owner = "Delapouite";
        repo = "kakoune-buffers";
        rev = "6b2081f5b7d58c72de319a5cba7bf628b6802881";
        sha256 = "sha256-jOSrzGcLJjLK1GiTSsl2jLmQMPbPxjycR0pwF5t/eV0=";
      };
      activationScript = ''
        # Suggested hook

        hook global WinDisplay .* info-buffers

        # Suggested mappings

        map global user b ':enter-buffers-mode<ret>'              -docstring 'buffers…'
        map global normal ^ ':enter-buffers-mode<ret>'              -docstring 'buffers…'
        map global user B ':enter-user-mode -lock buffers<ret>'   -docstring 'buffers (lock)…'

        # Suggested aliases

        alias global bd delete-buffer
        alias global bf buffer-first
        alias global bl buffer-last
        alias global bo buffer-only
        alias global bo! buffer-only-force
      '';
    }
  ];
  programs.my-kakoune.themes = {
    catppuccin-latte = ./catppuccin-latte.kak;
  };
}

