{ lib, fish, writeScript, writeTextDir, ... }:

let
  source-pwd = writeScript "source-pwd" ''
    #!/usr/bin/env ${lib.getExe fish}

    ${builtins.readFile ./source-pwd.fish}
  '';
in
writeTextDir "share/kak/kakrc.local" ''
  ${builtins.readFile ./kakrc}

  # Source any settings in the current working directory,
  # recursive upwards
  evaluate-commands %sh{
    ${source-pwd}
  }
''
