{ config, pkgs, lib, ... }:

let
  kakounePkg =
    pkgs.kakoune.override {
      kakoune = with lib; pkgs.stdenv.mkDerivation rec {
        pname = "kakoune-unwrapped";
        version = "r${builtins.substring 0 6 pkgs.sources.kakoune.rev}";
        src = pkgs.sources.kakoune;
        makeFlags = [ "debug=no" "PREFIX=${placeholder "out"}" ];

        preConfigure = ''
          export version="v${version}";
        '';

        enableParallelBuilding = true;

        doInstallCheck = true;
        installCheckPhase = ''
          $out/bin/kak -ui json -e "kill 0"
        '';

        postInstall = ''
          # make share/kak/autoload a directory
          cd "$out/share/kak"
          autoload_target=$(readlink autoload)
          rm autoload
          mkdir autoload
          ln -s --relative "$autoload_target" autoload
        '';
      };
    };

  kak-lsp = pkgs.libs.crane.buildPackage {
    src = pkgs.sources.kak-lsp;
    buildInputs = (with pkgs;
      lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Security SystemConfiguration CoreServices ])
    ) ++ (with pkgs; [ libiconv ]);
  };

in
{
  imports = [ ../modules/programs/my-kakoune ./kaktex.nix ];

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
  programs.kak-lsp.package = kak-lsp;
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

  programs.kak-lsp.languages.typescript = {
    args = [ "--stdio" ];
    command = "typescript-language-server";
    filetypes = [ "typescript" ];
    roots = [ "package.json" ];
  };
  programs.kak-lsp.languages.scala = {
    command = "metals";
    filetypes = [ "scala" ];
    roots = [ "build.sbt" "build.sc" ];
    settings_section = "metals";
    settings.metals = {
      enableSemanticHighlighting = true;
      showInferredType = true;
      decorationProvider = true;
      inlineDecorationProvider = true;
    };
  };
  programs.kak-lsp.languages.latex = {
    command = "texlab";
    filetypes = [ "latex" ];
    roots = [ ".git" "main.tex" "all.tex" ];
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
            args = [ "--synctex-forward" "%l:1:%f" "%p" "-x" "/home/nki/.bin/kaktex jump %{input} %{line}" ];
          });
    };
  };
  programs.kak-lsp.languages.typst = {
    command = "${pkgs.typst-lsp}/bin/typst-lsp";
    filetypes = [ "typst" ];
    roots = [ ".git" "main.typ" ];
    settings_section = "typst-lsp";
    settings.typst-lsp = { };
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
  programs.my-kakoune.tree-sitter.languages = {
    scala =
      let
        src = pkgs.fetchFromGitHub {
          owner = "tree-sitter";
          repo = "tree-sitter-scala";
          rev = "70afdd5632d57dd63a960972ab25945e353a52f6";
          hash =
            if pkgs.stdenv.isDarwin
            then lib.fakeHash
            else "sha256-xr43ejHGCH4mcjOqxTJpO11LWKcHKAEETt6ZWUG9vo4=";
          leaveDotGit = true;
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
          sha256 =
            if pkgs.stdenv.isDarwin
            then "sha256-lW3E4gSZV/m2RfofUqeiCu8KDz06YEvXbYKs8smXFi4="
            else "sha256-nocX9L8vD655nzky4PQulygWAjKGC1rh3SYDr7t4wBQ=";
          leaveDotGit = true;
        };
      in
      {
        grammar.src = src;
        grammar.compile.args = [ "-c" "-fpic" "../parser.c" "../scanner.c" "../unicode.h" "-I" ".." ];
        queries.src = src;
        queries.path = "queries";
      };
  };

  programs.my-kakoune.package = kakounePkg;
  programs.my-kakoune.rc =
    builtins.readFile ./kakrc + ''

      # Source any settings in the current working directory,
      # recursive upwards
      evaluate-commands %sh{
          ${pkgs.writeScript "source-pwd" (builtins.readFile ./source-pwd)}
      }
    '';

  programs.my-kakoune.extraFaces = {
    Default = "%opt{white},%opt{background}";
    BufferPadding = "%opt{background},%opt{background}";
    MenuForeground = "blue,white+bF";
    MenuBackground = "bright-blue,white+F";
    Information = "bright-blue,white";
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
    macro = "+b@function";
    method = "+i@function";
    format_specifier = "+i@string";
    mutable_variable = "+u@variable";
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
    catppuccin-latte = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/catppuccin/kakoune/f6d43770609433c45046632f1bb68d1395305dbb/colors/catppuccin_latte.kak";
      sha256 = "sha256:0ycvxs8hmsvd0zrpxiby16wzmapvmz6p34b6j343pc1girw6fi4i";
    };
  };
}

