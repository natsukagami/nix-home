{ lib
, callPackage
, formats
, runCommandLocal
, kak-tree-sitter
, ...
}:
let
  utils = callPackage ../utils.nix { };
  grammars = (callPackage ./grammars.nix { }).grammars;
  # Highlighter groups to add to the `highlighterGroups`. Maps from group names to face names.
  highlighterGroups = {
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
    spell = "%opt{mauve}";
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

  # Highlighter groups to be aliased by other groups
  aliases = {
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

  configDir =
    let
      toScm = name: lib.concatStringsSep "." (lib.splitString "_" name);

      toml = formats.toml { };
      file =
        toml.generate "config.toml" {
          highlight.groups = builtins.map toScm (builtins.attrNames highlighterGroups ++ builtins.attrNames aliases);
          features = {
            highlighting = true;
            text_objects = true;
          };
          language = grammars;
        };
    in
    runCommandLocal "kak-tree-sitter-config" { } ''
      mkdir -p $out/kak-tree-sitter
      ln -s ${file} $out/kak-tree-sitter/config.toml
    '';

  extraFaces =
    let
      toTs = name: "ts_${lib.concatStringsSep "_" (lib.splitString "." name)}";

      definedFaces = lib.mapAttrs' (name: value: { inherit value; name = toTs name; }) highlighterGroups;
      aliasFaces = lib.mapAttrs' (name: value: { name = toTs name; value = "@${toTs value}"; }) aliases;
      faces = lib.recursiveUpdate definedFaces aliasFaces;
    in
    faces;
in
{
  rc = ''
    # Enable kak-tree-sitter
    eval %sh{env XDG_CONFIG_DIR=${configDir} ${lib.getExe' kak-tree-sitter "kak-tree-sitter"} --kakoune -d --server --init $kak_session}
    map global normal <c-t> ": enter-user-mode tree-sitter<ret>"
  '';

  plugin = utils.mkFacesScript "kak-tree-sitter" extraFaces;
}

