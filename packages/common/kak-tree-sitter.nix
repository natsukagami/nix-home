{ lib, rustPlatform, fetchFromGitHub, symlinkJoin, clang, git, ... }:
let
  src = fetchFromGitHub {
    owner = "phaazon";
    repo = "kak-tree-sitter";
    rev = "61cce127ca03e3c969df1ff46f41074a3c69be31";
    hash = "sha256-wcgc1L6Y6obLTIonWLJzNK72fWW8oJ0yMEfGotCg5b8=";
  };

  kak-tree-sitter = rustPlatform.buildRustPackage rec {
    inherit src;
    pname = "kak-tree-sitter";
    version = "0.5.5-${lib.substring 0 6 src.rev}";
    cargoHash = "sha256-Ozzcn4k+1Q+50zxCy9Flvv8vZKNcAesrHT/izVAgn54=";
    cargoBuildOptions = [ "--package" "kak-tree-sitter" "--package" "ktsctl" ];

    nativeBuildInputs = [ clang git ];
  };
in
kak-tree-sitter
