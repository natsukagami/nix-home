{ lib, rustPlatform, fetchFromSourcehut, symlinkJoin, clang, git, writeText, ... }:
let
  src = fetchFromSourcehut {
    owner = "~hadronized";
    repo = "kak-tree-sitter";
    rev = "kak-tree-sitter-v1.1.3";
    hash = "sha256-vQZ+zQgwIw5ZBdIuMDD37rIdhe+WpNBmq0TciXBNiSU=";
  };

  kak-tree-sitter = rustPlatform.buildRustPackage {
    inherit src;
    pname = "kak-tree-sitter";
    version = "1.1.3";
    cargoHash = "sha256-1OwPfl1446SYt1556jwR9mvWOWEv+ab+wH7GZQeS4/E=";
    cargoBuildOptions = [ "--package" "kak-tree-sitter" "--package" "ktsctl" ];

    nativeBuildInputs = [ clang git ];

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

