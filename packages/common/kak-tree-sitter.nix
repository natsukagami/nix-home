{ lib, rustPlatform, fetchFromGitHub, symlinkJoin, clang, git, ... }:
let
  src = fetchFromGitHub {
    owner = "phaazon";
    repo = "kak-tree-sitter";
    rev = "fcc4ec36385ee5ce1378dae1b3eca4288619ff0d";
    sha256 = "sha256-a2EBTe6SucxHHMhElhnvyf3b6AOj5CyhHE7RHVx/Ulc=";
  };

  kak-tree-sitter = rustPlatform.buildRustPackage rec {
    inherit src;
    pname = "kak-tree-sitter";
    version = "0.3.0";
    cargoSha256 = "sha256-eDkIN7uzy2euywsjm3152R36B181Jj9KqnHsFDjyxhI=";
    cargoBuildOptions = [ "--package" "kak-tree-sitter" ];
  };

  ktsctl = rustPlatform.buildRustPackage rec {
    inherit src;
    name = "ktsctl";
    version = "0.2.0";
    cargoSha256 = "sha256-k16nuC50n9TSiGdkzP58gr6zpFR/Jh21Bw33SRWRi8U=";

    cargoBuildOptions = [ "--package" "ktsctl" ];

    buildInputs = [ clang git ];
  };
in
symlinkJoin {
  name = "kak-tree-sitter";
  paths = [ kak-tree-sitter ktsctl ];
}

