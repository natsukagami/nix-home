{ lib, rustPlatform, fetchFromGitHub, symlinkJoin, clang, git, ... }:
let
  src = fetchFromGitHub {
    owner = "phaazon";
    repo = "kak-tree-sitter";
    rev = "facf55f77171ae0d33332c6d54b5492e544f9ca1";
    hash = "sha256-XMHgP4SO2HT6NthQkKUwU1rOwVFXDp7FsM99zqM4Q04=";
  };

  kak-tree-sitter = rustPlatform.buildRustPackage rec {
    inherit src;
    pname = "kak-tree-sitter";
    version = "0.4.3";
    cargoHash = "sha256-JvMcwdllq0dacceZsI14cCnV7aW7wmU3h/Y9SAwHVtM=";
    cargoBuildOptions = [ "--package" "kak-tree-sitter" ];
  };

  ktsctl = rustPlatform.buildRustPackage rec {
    inherit src;
    name = "ktsctl";
    version = "0.3.1";
    cargoHash = "sha256-pyCUiekj79euOtS43mu9Fti+HZizaV069068h61uOT8=";

    cargoBuildOptions = [ "--package" "ktsctl" ];

    buildInputs = [ clang git ];
  };
in
symlinkJoin {
  name = "kak-tree-sitter";
  paths = [ kak-tree-sitter ktsctl ];
}

