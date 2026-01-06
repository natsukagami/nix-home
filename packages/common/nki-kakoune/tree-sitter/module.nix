{
  config,
  pkgs,
  lib,
  kakoune-util,
  ...
}:
with lib;
let
  cfg = config.nki-kakoune.tree-sitter;

  languageModule = types.submodule {
    options = {
      # Grammar
      grammar.src = mkOption {
        type = types.package;
        description = "The repo to be used";
      };
      grammar.path = mkOption {
        type = types.str;
        default = "src";
      };
      grammar.compile = {
        command = mkOption {
          type = types.str;
          default = "${pkgs.gcc}/bin/gcc";
        };
        args = mkOption {
          type = types.listOf types.str;
          default = [
            "-c"
            "-fpic"
            "../parser.c"
            "../scanner.c"
            "-I"
            ".."
          ];
        };
        flags = mkOption {
          type = types.listOf types.str;
          default = [ "-O3" ];
        };
      };
      grammar.link = {
        command = mkOption {
          type = types.str;
          default = "${pkgs.gcc}/bin/gcc";
        };
        args = mkOption {
          type = types.listOf types.str;
          default = [
            "-shared"
            "-fpic"
            "parser.o"
            "scanner.o"
          ];
        };
        flags = mkOption {
          type = types.listOf types.str;
          default = [ "-O3" ];
        };
      };
      # Queries
      queries.src = mkOption {
        type = types.package;
        description = "The repo to be used";
      };
      queries.path = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      # Other options
      remove_default_highlighter = mkOption {
        type = types.bool;
        default = true;
      };
      filetype_hook = mkOption {
        type = types.bool;
        default = true;
      };
      aliases = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };
  mkGrammarPackage =
    {
      name,
      src,
      grammarPath ? "src",
      grammarCompileArgs ? [
        "-O3"
        "-c"
        "-fpic"
        "../parser.c"
        "../scanner.c"
        "-I"
        ".."
      ],
      grammarLinkArgs ? [
        "-shared"
        "-fpic"
        "parser.o"
        "scanner.o"
      ],
    }:
    pkgs.stdenv.mkDerivation {
      inherit src;
      name = "kak-tree-sitter-grammar-${name}.so";
      version = "latest";
      buildPhase = ''
        mkdir ${grammarPath}/build
        cd ${grammarPath}/build
        $CC ${lib.concatStringsSep " " grammarCompileArgs}
        $CC ${lib.concatStringsSep " " grammarLinkArgs} -o ${name}.so
      '';
      installPhase = ''
        cp ${name}.so $out
      '';
    };

in
{
  options.nki-kakoune.tree-sitter = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable kak-tree-sitter";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../../kak-tree-sitter { };
    };

    features = {
      highlighting = mkOption {
        type = types.bool;
        description = "Enable highlighting";
        default = true;
      };
      text_objects = mkOption {
        type = types.bool;
        description = "Enable text objects";
        default = true;
      };
    };

    highlighterGroups = mkOption {
      type = types.attrsOf types.str;
      default = {
        attribute = "@attribute";
        comment = "@comment";
        conceal = "%opt{mauve}+i";
        constant = "%opt{peach}";
        constant_builtin_boolean = "%opt{sky}";
        constant_character = "%opt{yellow}";
        constant_macro = "%opt{mauve}";
        constant_numeric = "%opt{peach}";
        constructor = "%opt{sapphire}";
        diff_plus = "%opt{green}";
        diff_minus = "%opt{red}";
        diff_delta = "%opt{blue}";
        diff_delta_moved = "%opt{mauve}";
        error = "%opt{red}+b";
        function = "@function";
        function_builtin = "@builtin";
        function_macro = "+i@ts_function";
        hint = "%opt{blue}+b";
        info = "%opt{green}+b";
        keyword = "keyword";
        keyword_conditional = "+i@ts_keyword";
        keyword_control_conditional = "+i@ts_keyword";
        keyword_control_directive = "+i@ts_keyword";
        keyword_control_import = "+i@ts_keyword";
        keyword_directive = "+i@ts_keyword";
        label = "%opt{sapphire}+i";
        markup_bold = "%opt{peach}+b";
        markup_heading = "%opt{red}";
        markup_heading_1 = "%opt{red}";
        markup_heading_2 = "%opt{mauve}";
        markup_heading_3 = "%opt{green}";
        markup_heading_4 = "%opt{yellow}";
        markup_heading_5 = "%opt{pink}";
        markup_heading_6 = "%opt{teal}";
        markup_heading_marker = "%opt{peach}+b";
        markup_italic = "%opt{pink}+i";
        markup_list_checked = "%opt{green}";
        markup_list_numbered = "%opt{blue}+i";
        markup_list_unchecked = "%opt{teal}";
        markup_list_unnumbered = "%opt{mauve}";
        markup_link_label = "%opt{blue}";
        markup_link_url = "%opt{teal}+u";
        markup_link_uri = "%opt{teal}+u";
        markup_link_text = "%opt{blue}";
        markup_quote = "%opt{crust}";
        markup_raw = "%opt{sky}";
        markup_raw_block = "%opt{sky}";
        markup_raw_inline = "%opt{green}";
        markup_strikethrough = "%opt{crust}+s";
        namespace = "@module";
        operator = "@operator";
        property = "%opt{sky}";
        punctuation = "%opt{overlay2}";
        punctuation_special = "%opt{sky}";
        special = "%opt{blue}";
        string = "%opt{green}";
        string_regex = "%opt{peach}";
        string_regexp = "%opt{peach}";
        string_escape = "%opt{mauve}";
        string_special = "%opt{blue}";
        string_special_path = "%opt{green}";
        string_special_symbol = "%opt{mauve}";
        string_symbol = "%opt{red}";
        tag = "%opt{teal}";
        tag_error = "%opt{red}";
        text_title = "%opt{mauve}";
        type = "@type";
        type_enum_variant = "+i@ts_type";
        variable = "@variable";
        variable_builtin = "@builtin";
        variable_other_member = "%opt{teal}";
        variable_parameter = "+i@variable";
        warning = "%opt{peach}+b";
      };
    };

    extraHighlighterGroups = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Highlighter groups to add to the `highlighterGroups`. Maps from group names to face names.";
    };

    aliases = mkOption {
      type = types.attrsOf types.str;
      default = {
        comment_block = "comment";
        comment_line = "comment";
        comment_documentation = "info";
        constant_character_escape = "constant_character";
        constant_numeric_float = "constant_numeric";
        constant_numeric_integer = "constant_numeric";
        function_method = "function";
        function_special = "function";
        keyword_control = "keyword";
        keyword_control_repeat = "keyword";
        keyword_control_return = "keyword";
        keyword_control_except = "keyword";
        keyword_control_exception = "keyword";
        keyword_function = "keyword";
        keyword_operator = "keyword";
        keyword_special = "keyword";
        keyword_storage = "keyword";
        keyword_storage_modifier = "keyword";
        keyword_storage_modifier_mut = "keyword";
        keyword_storage_modifier_ref = "keyword";
        keyword_storage_type = "keyword";
        punctuation_bracket = "punctuation";
        punctuation_delimiter = "punctuation";
        text = "string";
        type_builtin = "type";
      };
      description = "Highlighter groups to be aliased by other groups";
    };

    extraAliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra highlighter groups to be aliased by other groups";
    };

    languages = mkOption {
      type = types.attrsOf languageModule;
      default = { };
    };
  };

  config =
    let
      allGroups = attrsets.recursiveUpdate cfg.highlighterGroups cfg.extraHighlighterGroups;

      aliases = attrsets.recursiveUpdate cfg.aliases cfg.extraAliases;

      toTs = name: "ts_${strings.concatStringsSep "_" (strings.splitString "." name)}";
      toScm = name: strings.concatStringsSep "." (strings.splitString "_" name);

      definedFaces = lib.mapAttrsToList (name: value: {
        name = toTs name;
        face = value;
      }) allGroups;
      aliasFaces = lib.mapAttrsToList (name: value: {
        name = toTs name;
        face = "@${toTs value}";
      }) aliases;
      faces = definedFaces ++ aliasFaces;

      toml = pkgs.formats.toml { };

      toGrammarConf =
        name: lang: with lang; {
          source.local.path = mkGrammarPackage {
            inherit name;
            src = grammar.src;
            grammarPath = grammar.path;
            grammarCompileArgs = grammar.compile.flags ++ grammar.compile.args;
            grammarLinkArgs = grammar.link.flags ++ grammar.link.args;
          };
          compile = grammar.compile.command;
          compile_args = grammar.compile.args;
          compile_flags = grammar.compile.flags;
          link = grammar.link.command;
          link_args = grammar.link.args ++ [
            "-o"
            "${name}.so"
          ];
          link_flags = grammar.link.flags;
        };

      toLanguageConf =
        name: lang:
        (builtins.removeAttrs lang [
          "grammar"
          "queries"
        ])
        // (with lang; {
          queries = rec {
            path = if queries.path == null then "runtime/queries/${name}" else queries.path;
            source.local.path = "${queries.src}/${path}";
          };
        });

      configFile = toml.generate "kak-tree-sitter-config.toml" {
        highlight.groups = builtins.map toScm (builtins.attrNames allGroups ++ builtins.attrNames aliases);
        features = cfg.features;
        language = builtins.mapAttrs toLanguageConf cfg.languages;
        grammar = builtins.mapAttrs toGrammarConf cfg.languages;
      };
    in
    mkIf cfg.enable {
      # assertions =
      #   with lib.asserts;
      #   (
      #     [ ]
      #     ++ attrsets.mapAttrsToList (name: _: {
      #       assertion = (!(builtins.hasAttr name allGroups));
      #       message = "${name} was both defined and aliased";
      #     }) aliases
      #   );
      #
      nki-kakoune.extraPackages = [ cfg.package ];

      nki-kakoune.buildPhase = ''
        makeWrapper ${lib.getExe' cfg.package "ktsctl"} $out/bin/ktsctl \
          --add-flag "--config=${configFile}" \
          --suffix PATH ":" "${lib.makeBinPath [ pkgs.gcc ]}"
      '';

      nki-kakoune.plugins."kak-tree-sitter" =
        pkgs.writeTextDir "share/kak/autoload/kak-tree-sitter.kak" ''
          # Enable kak-tree-sitter
          eval %sh{kak-tree-sitter --kakoune -d --server --init $kak_session --config ${configFile}}
          map global normal <c-t> ": enter-user-mode tree-sitter<ret>"

          ${kakoune-util.mkFacesScript' faces}
        '';
    };

}
