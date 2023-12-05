{ lib, rustPlatform, fetchFromGitHub, symlinkJoin, clang, git, ... }:
let
  src = fetchFromGitHub {
    owner = "phaazon";
    repo = "kak-tree-sitter";
    rev = "kak-tree-sitter-v0.5.2";
    hash = "sha256-oyb1mczin1CEZwG1YBJfy1dSEYpNpqmZ21mscrgkoBo=";
  };

  kak-tree-sitter = rustPlatform.buildRustPackage rec {
    inherit src;
    pname = "kak-tree-sitter";
    version = "0.5.2";
    cargoHash = "sha256-rvysHMMiI1e6RBKX+NFObB8fXGmzVnc+4/A5qPcEcm8=";
    cargoBuildOptions = [ "--package" "kak-tree-sitter" "--package" "ktsctl" ];

    nativeBuildInputs = [ clang git ];
  };
in
kak-tree-sitter
