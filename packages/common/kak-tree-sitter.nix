{ lib, rustPlatform, fetchFromGitHub, symlinkJoin, clang, git, ... }:
let
  src = fetchFromGitHub {
    owner = "phaazon";
    repo = "kak-tree-sitter";
    rev = "3567f648bbf6a5d556c43bde5433dff45eabd693";
    hash = "sha256-xr7CtOfMO4nRu2MOIQX3jR0wsKGsjYiF/TGXSAsidM4=";
  };

  kak-tree-sitter = rustPlatform.buildRustPackage rec {
    inherit src;
    pname = "kak-tree-sitter";
    version = "0.4.6";
    cargoHash = "sha256-6HJxJTr4P1/6Yy3/dtfiaCFoHA4iKvmuwg51jTYU2eo=";
    cargoBuildOptions = [ "--package" "kak-tree-sitter" "--package" "ktsctl" ];

    nativeBuildInputs = [ clang git ];
  };
in
kak-tree-sitter
