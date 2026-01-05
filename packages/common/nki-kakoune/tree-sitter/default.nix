{ pkgs, ... }:
{
  imports = [ ./module.nix ];
  nki-kakoune.tree-sitter.extraAliases = {
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
  nki-kakoune.tree-sitter.languages =
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
          grammar.compile.args = [
            "-c"
            "-fpic"
            "../parser.c"
            "../scanner.c"
            "../unicode.h"
            "-I"
            ".."
          ];
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
        grammar.compile.args = [
          "-c"
          "-fpic"
          "../scanner.cc"
          "../parser.c"
          "-I"
          ".."
        ];
        grammar.link.args = [
          "-shared"
          "-fpic"
          "scanner.o"
          "parser.o"
        ];
        grammar.link.flags = [
          "-O3"
          "-lstdc++"
        ];

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
            rev = "4519e3ec9ca92754ca25659bb1fd410d5e0f8d88";
            hash = "sha256-ic5SlqDEZoYakrJFe0H9GdzravqovlL5sTaHjyhe74M=";
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
        grammar.compile.args = [
          "-c"
          "-fpic"
          "../parser.c"
          "-I"
          ".."
        ];
        grammar.link.args = [
          "-shared"
          "-fpic"
          "parser.o"
        ];
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
          grammar.compile.args = [
            "-c"
            "-fpic"
            "../parser.c"
            "-I"
            ".."
          ];
          grammar.link.args = [
            "-shared"
            "-fpic"
            "parser.o"
          ];
          queries.src = src;
          queries.path = "queries";
        };
      swift =
        let
          src = pkgs.fetchFromGitHub {
            owner = "alex-pinkus";
            repo = "tree-sitter-swift";
            rev = "with-generated-files";
            hash = "sha256-BVOCGYUSEXpu2Mu7VRVCZrBBqZpZdK3oLm3aYmOH+cs=";
          };
        in
        {
          grammar.src = src;
          grammar.compile.args = [
            "-c"
            "-fpic"
            "../scanner.c"
            "../parser.c"
            "-I"
            ".."
          ];
          grammar.link.args = [
            "-shared"
            "-fpic"
            "scanner.o"
            "parser.o"
          ];
          queries.src = src;
          queries.path = "queries";
        };
    };
}
