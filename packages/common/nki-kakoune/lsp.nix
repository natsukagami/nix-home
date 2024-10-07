{ lib
, writeTextDir
, formats
, kak-lsp
, # LSP packages
  ccls
, gopls
, nil
, nixpkgs-fmt
, python311Packages
, ltex-ls
, nodePackages
, tailwindcss-language-server
, fsautocomplete
, metals
, texlab
, marksman
, rust-analyzer
, ...
}:
let
  # Configuration for kak-lsp
  config = {
    languageIDs = {
      c = "c_cpp";
      cpp = "c_cpp";
      javascript = "javascriptreact";
      typescript = "typescriptreact";
      protobuf = "proto";
      sh = "shellscript";
    };

    languageServers =
      let
        vscodeServerOf = name: {
          name = "vscode-${name}-language-server";
          value = {
            args = [ "--stdio" ];
            command = "vscode-${name}-language-server";
            filetypes = [ name "templ" ];
            roots = [ "package.json" ".git" ];
          };
          package = nodePackages.vscode-langservers-extracted;
        };
      in
      {
        ccls = {
          args = [ "-v=2" "-log-file=/tmp/ccls.log" ];
          package = ccls;
          command = "ccls";
          filetypes = [ "c" "cpp" ];
          roots = [ "compile_commands.json" ".cquery" ".git" ];
        };
        gopls = {
          command = "gopls";
          package = gopls;
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
        nil = {
          command = "nil";
          package = nil;
          filetypes = [ "nix" ];
          roots = [ "flake.nix" "shell.nix" ".git" ];
          settings.nil = {
            formatting.command = [ "${lib.getExe nixpkgs-fmt}" ];
          };
        };
        pylsp = {
          command = "pylsp";
          package = python311Packages.python-lsp-server;
          filetypes = [ "python" ];
          offset_encoding = "utf-8";
          roots = [ "requirements.txt" "setup.py" ".git" ".hg" ];
        };
        # Spellchecking server
        ltex-ls = {
          command = "ltex-ls";
          args = [ "--log-file=/tmp" ];
          filetypes = [ "latex" "typst" ];
          roots = [ "main.tex" "main.typ" ".git" ];
          package = ltex-ls;
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
          package = tailwindcss-language-server;
        };
        elixir-ls = {
          args = [ ];
          command = "elixir-ls";
          filetypes = [ "elixir" ];
          roots = [ "mix.exs" ];
        };
        typescript-language-server = {
          args = [ "--stdio" ];
          command = "typescript-language-server";
          filetypes = [ "typescript" "javascript" ];
          roots = [ "package.json" ];
          package = nodePackages.typescript-language-server;
        };
        fsautocomplete = {
          args = [ "--adaptive-lsp-server-enabled" "--project-graph-enabled" "--source-text-factory" "RoslynSourceText" ];
          command = "fsautocomplete";
          filetypes = [ "fsharp" ];
          roots = [ "*.fsproj" ];
          settings_section = "FSharp";
          settings.FSharp = {
            AutomaticWorkspaceInit = true;
          };
          package = fsautocomplete;
        };
        metals = {
          command = "metals";
          filetypes = [ "scala" ];
          roots = [ "build.sbt" "build.sc" ];
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
          package = metals;
        };
        texlab = {
          command = "texlab";
          filetypes = [ "latex" ];
          roots = [ "main.tex" "all.tex" ".git" ];
          settings_section = "texlab";
          settings.texlab = {
            build.executable = "latexmk";
            build.args = [ "-pdf" "-shell-escape" "-interaction=nonstopmode" "-synctex=1" "%f" ];

            build.forwardSearchAfter = true;
            build.onSave = true;

            # forwardSearch =
            #   (if pkgs.stdenv.isDarwin then {
            #     executable = "/Applications/Skim.app/Contents/SharedSupport/displayline";
            #     args = [ "-r" "-g" "%l" "%p" "%f" ];
            #   } else
            #     {
            #       executable = "${pkgs.zathura}/bin/zathura";
            #       args = [ "--synctex-forward" "%l:1:%f" "%p" "-x" "${./kaktex} jump %%{input} %%{line} %%{column}" ];
            #     });
          };
          package = texlab;
        };
        typst-lsp = {
          command = "typst-lsp";
          filetypes = [ "typst" ];
          roots = [ "main.typ" ".git" ];
          settings_section = "typst-lsp";
          settings.typst-lsp = {
            experimentalFormatterMode = "on";
          };
        };
        marksman = {
          command = "marksman";
          filetypes = [ "markdown" ];
          roots = [ ".marksman.toml" ".git" ];
          package = marksman;
        };
        rust-analyzer = {
          args = [ ];
          command = "rust-analyzer";
          filetypes = [ "rust" ];
          roots = [ "Cargo.toml" ];
          package = rust-analyzer;
        };

      } // (builtins.listToAttrs (builtins.map vscodeServerOf [ "html" "css" "json" ]));

    faces = [
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

    raw = {
      server = { timeout = 1800; };
      snippet_support = false;
      verbosity = 255;
    };
  };

  kak-lsp-config =
    let
      toml = formats.toml { };
      toLspConfig = attrs: builtins.removeAttrs attrs [ "package" ];
    in
    toml.generate "kak-lsp.toml" ({
      semantic_tokens.faces = config.faces;
      language_server = toLspConfig config.languageServers;
      language_ids = config.languageIDs;
    } // config.raw);

  serverPackages =
    builtins.filter (v: v != null)
      (lib.mapAttrsToList (_: serv: serv.package or null) config.languageServers);
in
{
  extraPaths = lib.makeBinPath serverPackages;
  plugin = writeTextDir "share/kak/autoload/kak-lsp.kak" ''
    hook global KakBegin .* %{
      try %{
        eval %sh{${lib.getExe kak-lsp} --config ${kak-lsp-config} -s $kak_session}
      }

      lsp-enable
      map window lsp N -docstring "Display the next message request" ": lsp-show-message-request-next<ret>"
      map window normal <c-l> ": enter-user-mode lsp<ret>"
      map window normal <c-h> ": lsp-hover<ret>"
      map window normal <c-s-h> ": lsp-hover-buffer<ret>"
      # lsp-auto-hover-insert-mode-enable
      set window lsp_hover_anchor true
      map global insert <tab> '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>' -docstring 'Select next snippet placeholder'
      map global object a '<a-semicolon>lsp-object<ret>' -docstring 'LSP any symbol'
      map global object <a-a> '<a-semicolon>lsp-object<ret>' -docstring 'LSP any symbol'
      map global object f '<a-semicolon>lsp-object Function Method<ret>' -docstring 'LSP function or method'
      map global object t '<a-semicolon>lsp-object Class Interface Struct<ret>' -docstring 'LSP class interface or struct'
      map global object d '<a-semicolon>lsp-diagnostic-object --include-warnings<ret>' -docstring 'LSP errors and warnings'
      map global object D '<a-semicolon>lsp-diagnostic-object<ret>' -docstring 'LSP errors'

      hook global WinSetOption filetype=(racket|rust|python|go|javascript|typescript|c|cpp|tex|latex|haskell|nix|fsharp|templ) %{
          # Format the document if possible
          hook window BufWritePre .* %{ lsp-formatting-sync }
      }

      hook global WinSetOption filetype=(rust|scala|fsharp) %{
          # Enable inlay hints
          lsp-inlay-hints-enable window
      }

      hook global WinSetOption filetype=(rust|go|fsharp|typst|scala) %{
        hook window -group semantic-tokens BufReload .* lsp-semantic-tokens
        hook window -group semantic-tokens NormalIdle .* lsp-semantic-tokens
        hook window -group semantic-tokens InsertIdle .* lsp-semantic-tokens
        hook -once -always window WinSetOption filetype=.* %{
          remove-hooks window semantic-tokens
        }
      }
    }
  '';
}

