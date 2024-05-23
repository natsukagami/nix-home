{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.programs.my-kakoune.tree-sitter;

  languageModule = types.submodule {
    options = {
      grammar.src = mkOption {
        type = types.package;
        description = "The repo to be used";
      };
      grammar.path = mkOption {
        type = types.str;
        default = "src";
      };
      grammar.compile = {
        command = mkOption { type = types.str; default = "${pkgs.gcc}/bin/gcc"; };
        args = mkOption { type = types.listOf types.str; default = [ "-c" "-fpic" "../parser.c" "../scanner.c" "-I" ".." ]; };
        flags = mkOption { type = types.listOf types.str; default = [ "-O3" ]; };
      };
      grammar.link = {
        command = mkOption { type = types.str; default = "${pkgs.gcc}/bin/gcc"; };
        args = mkOption { type = types.listOf types.str; default = [ "-shared" "-fpic" "parser.o" "scanner.o" ]; };
        flags = mkOption { type = types.listOf types.str; default = [ "-O3" ]; };
      };
      queries.src = mkOption {
        type = types.package;
        description = "The repo to be used";
      };
      queries.path = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };
in
{
  options.programs.my-kakoune.tree-sitter = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable kak-tree-sitter";
    };
    package = mkPackageOption pkgs "kak-tree-sitter" { };

    highlighterGroups = mkOption {
      type = types.attrsOf types.str;
      default = {
        attribute = "@attribute";
        comment = "@comment";
        conceal = "%opt{kts_mauve}+i";
        constant = "%opt{kts_peach}";
        constant_builtin_boolean = "%opt{kts_sky}";
        constant_character = "%opt{kts_yellow}";
        constant_macro = "%opt{kts_mauve}";
        constant_numeric = "%opt{kts_peach}";
        constructor = "%opt{kts_sapphire}";
        diff_plus = "%opt{kts_green}";
        diff_minus = "%opt{kts_red}";
        diff_delta = "%opt{kts_blue}";
        diff_delta_moved = "%opt{kts_mauve}";
        error = "%opt{kts_red}+b";
        function = "@function";
        function_builtin = "@builtin";
        function_macro = "+i@ts_function";
        hint = "%opt{kts_blue}+b";
        info = "%opt{kts_green}+b";
        keyword = "keyword";
        keyword_conditional = "+i@ts_keyword";
        keyword_control_conditional = "+i@ts_keyword";
        keyword_control_directive = "+i@ts_keyword";
        keyword_control_import = "+i@ts_keyword";
        keyword_directive = "+i@ts_keyword";
        label = "%opt{kts_sapphire}+i";
        markup_bold = "%opt{kts_peach}+b";
        markup_heading = "%opt{kts_red}";
        markup_heading_1 = "%opt{kts_red}";
        markup_heading_2 = "%opt{kts_mauve}";
        markup_heading_3 = "%opt{kts_green}";
        markup_heading_4 = "%opt{kts_yellow}";
        markup_heading_5 = "%opt{kts_pink}";
        markup_heading_6 = "%opt{kts_teal}";
        markup_heading_marker = "%opt{kts_peach}+b";
        markup_italic = "%opt{kts_pink}+i";
        markup_list_checked = "%opt{kts_green}";
        markup_list_numbered = "%opt{kts_blue}+i";
        markup_list_unchecked = "%opt{kts_teal}";
        markup_list_unnumbered = "%opt{kts_mauve}";
        markup_link_label = "%opt{kts_blue}";
        markup_link_url = "%opt{kts_teal}+u";
        markup_link_uri = "%opt{kts_teal}+u";
        markup_link_text = "%opt{kts_blue}";
        markup_quote = "%opt{kts_gray1}";
        markup_raw = "%opt{kts_sky}";
        markup_raw_block = "%opt{kts_sky}";
        markup_raw_inline = "%opt{kts_green}";
        markup_strikethrough = "%opt{kts_gray1}+s";
        namespace = "@module";
        operator = "@operator";
        property = "%opt{kts_sky}";
        punctuation = "%opt{kts_overlay2}";
        punctuation_special = "%opt{kts_sky}";
        special = "%opt{kts_blue}";
        spell = "%opt{kts_mauve}";
        string = "%opt{kts_green}";
        string_regex = "%opt{kts_peach}";
        string_regexp = "%opt{kts_peach}";
        string_escape = "%opt{kts_mauve}";
        string_special = "%opt{kts_blue}";
        string_special_path = "%opt{kts_green}";
        string_special_symbol = "%opt{kts_mauve}";
        string_symbol = "%opt{kts_red}";
        tag = "%opt{kts_teal}";
        tag_error = "%opt{kts_red}";
        text_title = "%opt{kts_mauve}";
        type = "%opt{kts_yellow}";
        type_enum_variant = "%opt{kts_flamingo}";
        variable = "@variable";
        variable_builtin = "@builtin";
        variable_other_member = "%opt{kts_teal}";
        variable_parameter = "%opt{kts_maroon}+i";
        warning = "%opt{kts_peach}+b";
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
      aliasedOnce = name: values: if asserts.assertMsg (builtins.length values 1) "face ${name} was aliased more than once: ${toString values}" then (builtins.head values) else [ ];

      allGroups = attrsets.recursiveUpdate cfg.highlighterGroups cfg.extraHighlighterGroups;

      aliases = attrsets.recursiveUpdate cfg.aliases cfg.extraAliases;

      toTs = name: "ts_${strings.concatStringsSep "_" (strings.splitString "." name)}";
      toScm = name: strings.concatStringsSep "." (strings.splitString "_" name);

      definedFaces = attrsets.mapAttrs' (name: value: { inherit value; name = toTs name; }) allGroups;
      aliasFaces = attrsets.mapAttrs' (name: value: { name = toTs name; value = "@${toTs value}"; }) aliases;
      faces = attrsets.recursiveUpdate definedFaces aliasFaces;

      toml = pkgs.formats.toml { };

      toLanguageConf = name: lang: with lang; {
        grammar = {
          inherit (grammar) path;
          url = "${grammar.src}";
          compile = grammar.compile.command;
          compile_args = grammar.compile.args;
          compile_flags = grammar.compile.flags;
          link = grammar.link.command;
          link_args = grammar.link.args ++ [ "-o" "${name}.so" ];
          link_flags = grammar.link.flags;
        };
        queries = {
          url = "${queries.src}";
          path = if queries.path == null then "runtime/queries/${name}" else queries.path;
        };
      };
    in
    mkIf cfg.enable {
      assertions = with lib.asserts; ([ ]
        ++ attrsets.mapAttrsToList
        (name: _: {
          assertion = (! (builtins.hasAttr name allGroups));
          message = "${name} was both defined and aliased";
        })
        aliases
      );
      home.packages = [ cfg.package ];

      xdg.configFile."kak-tree-sitter/config.toml" = {
        source = toml.generate "config.toml" {
          highlight.groups = builtins.map toScm (builtins.attrNames allGroups ++ builtins.attrNames aliases);

          language = builtins.mapAttrs toLanguageConf cfg.languages;
        };

        onChange =
          let
            buildCmd = lang: "${cfg.package}/bin/ktsctl -fci ${lang}";
            buildAll = strings.concatMapStringsSep "\n" buildCmd (builtins.attrNames cfg.languages);
          in
          ''
            # Rebuild languages
            ${buildAll}
          '';
      };

      programs.my-kakoune.extraFaces = faces;
    };

}

