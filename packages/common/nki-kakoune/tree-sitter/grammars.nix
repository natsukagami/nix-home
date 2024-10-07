{ lib, stdenv, fetchFromGitHub, runCommandLocal, ... }:
let
  mkGrammarPackage =
    { name
    , src
    , grammarPath ? "src"
    , grammarCompileArgs ? [ "-O3" "-c" "-fpic" "../parser.c" "../scanner.c" "-I" ".." ]
    , grammarLinkArgs ? [ "-shared" "-fpic" "parser.o" "scanner.o" ]
    , ...
    }: stdenv.mkDerivation {
      inherit src;
      name = "kak-tree-sitter-grammar-${name}";
      version = "latest";
      buildPhase = ''
        mkdir ${grammarPath}/build
        cd ${grammarPath}/build
        $CC ${lib.concatStringsSep " " grammarCompileArgs}
        $CC ${lib.concatStringsSep " " grammarLinkArgs} -o ${name}.so
      '';
      installPhase = ''
        mkdir $out
        cp ${name}.so $out
      '';
    };
  mkGrammar =
    args @ { name
    , src
    , grammarPath ? "src"
    , grammarCompileArgs ? [ "-O3" "-c" "-fpic" "../parser.c" "../scanner.c" "-I" ".." ]
    , grammarLinkArgs ? [ "-shared" "-fpic" "parser.o" "scanner.o" ]
    , querySrc ? src
    , queryPath ? "runtime/queries/${name}"
    ,
    }: {
      grammar.source.local.path = "${mkGrammarPackage args}";
      queries.source.local.path = querySrc;
      queries.path = queryPath;
    };

  tree-sitter-go = fetchFromGitHub {
    owner = "tree-sitter";
    repo = "tree-sitter-go";
    rev = "v0.20.0";
    hash = "sha256-G7d8CHCyKDAb9j6ijRfHk/HlgPqSI+uvkuRIRRvjkHI=";
  };
in
{
  grammars = builtins.mapAttrs (name: value: mkGrammar ({ inherit name; } // value)) {
    scala = {
      src = fetchFromGitHub {
        owner = "tree-sitter";
        repo = "tree-sitter-scala";
        rev = "70afdd5632d57dd63a960972ab25945e353a52f6";
        hash = "sha256-bi0Lqo/Zs2Uaz1efuKAARpEDg5Hm59oUe7eSXgL1Wow=";
      };
      queryPath = "queries/scala";
    };
    haskell = {
      src = fetchFromGitHub {
        owner = "tree-sitter";
        repo = "tree-sitter-haskell";
        rev = "ba0bfb0e5d8e9e31c160d287878c6f26add3ec08";
        hash = "sha256-ZSOF0CLOn82GwU3xgvFefmh/AD2j5zz8I0t5YPwfan0=";
      };
      grammarCompileArgs = [ "-O3" "-c" "-fpic" "../parser.c" "../scanner.c" "../unicode.h" "-I" ".." ];
      queryPath = "queries";
    };
    yaml = {
      src = fetchFromGitHub {
        owner = "ikatyang";
        repo = "tree-sitter-yaml";
        rev = "0e36bed171768908f331ff7dff9d956bae016efb";
        hash = "sha256-bpiT3FraOZhJaoiFWAoVJX1O+plnIi8aXOW2LwyU23M=";
      };
      grammarCompileArgs = [ "-c" "-fpic" "../scanner.cc" "../parser.c" "-I" ".." ];
      grammarLinkArgs = [ "-lstdc++" "-shared" "-fpic" "scanner.o" "parser.o" ];
      querySrc = fetchFromGitHub {
        owner = "helix-editor";
        repo = "helix";
        rev = "dbd248fdfa680373d94fbc10094a160aafa0f7a7";
        hash = "sha256-wk8qVUDFXhAOi1Ibc6iBMzDCXb6t+YiWZcTd0IJybqc=";
      };
    };
    templ = rec {
      src = fetchFromGitHub {
        owner = "vrischmann";
        repo = "tree-sitter-templ";
        rev = "044ad200092170727650fa6d368df66a8da98f9d";
        hash = "sha256-hJuB3h5pp+LLfP0/7bAYH0uLVo+OQk5jpzJb3J9BNkY=";
      };
      querySrc = runCommandLocal "templ-tree-sitter-queries" { } ''
        mkdir -p $out/queries
        # copy most stuff from tree-sitter-templ
        install -m644 ${src}/queries/templ/* $out/queries
        # override inherited files
        cat ${tree-sitter-go}/queries/highlights.scm ${src}/queries/templ/highlights.scm > $out/queries/highlights.scm
      '';
      queryPath = "queries";
    };
    go = {
      src = tree-sitter-go;
      grammarCompileArgs = [ "-O3" "-c" "-fpic" "../parser.c" "-I" ".." ];
      grammarLinkArgs = [ "-shared" "-fpic" "parser.o" ];
      queryPath = "queries";
    };
    hylo = {
      src = fetchFromGitHub {
        owner = "natsukagami";
        repo = "tree-sitter-hylo";
        rev = "494cbdff0d13cbc67348316af2efa0286dbddf6f";
        hash = "sha256-R5UeoglCTl0do3VDJ/liCTeqbxU9slvmVKNRA/el2VY=";
      };
      grammarCompileArgs = [ "-O3" "-c" "-fpic" "../parser.c" "-I" ".." ];
      grammarLinkArgs = [ "-shared" "-fpic" "parser.o" ];
      queryPath = "queries";
    };
  };
}

