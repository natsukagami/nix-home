{
  lib,
  rustPlatform,
  fetchFromSourcehut,
  symlinkJoin,
  clang,
  git,
  writeText,
  ...
}:
let
  src = fetchFromSourcehut {
    owner = "~hadronized";
    repo = "kak-tree-sitter";
    rev = "kak-tree-sitter-v3.1.1";
    hash = "sha256-iDpWzvtM0xQSEqs+TsfW3AGaMYwYkHwWqKrbWPRposc=";
  };

  kak-tree-sitter = rustPlatform.buildRustPackage {
    inherit src;
    pname = "kak-tree-sitter";
    version = "3.1.1";
    cargoLock.lockFile = "${src}/Cargo.lock";

    cargoBuildOptions = [
      "--package"
      "kak-tree-sitter"
      "--package"
      "ktsctl"
    ];

    nativeBuildInputs = [
      clang
      git
    ];

    patches = [
      # Allow absolute-path style repos
      (writeText "resources.patch" ''
        diff --git a/ktsctl/src/resources.rs b/ktsctl/src/resources.rs
        index f1da3ff..ac89345 100644
        --- a/ktsctl/src/resources.rs
        +++ b/ktsctl/src/resources.rs
        @@ -48,7 +48,8 @@ impl Resources {
               url
                 .trim_start_matches("http")
                 .trim_start_matches('s')
        -        .trim_start_matches("://"),
        +        .trim_start_matches(":/")
        +        .trim_start_matches("/"),
             );

             self.runtime_dir.join("sources").join(url_dir)
      '')
    ];

    meta.mainProgram = "kak-tree-sitter";
  };
in
kak-tree-sitter
