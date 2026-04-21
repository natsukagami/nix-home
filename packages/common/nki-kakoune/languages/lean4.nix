{
  lib,
  elan,
  perl,
  fetchFromGitHub,
  sd,
  util,
  ...
}:
let
  perlJSON = perl.withPackages (p: [ p.JSON ]);
in
{
  plugin = util.kakounePlugin {
    name = "lean4.kak";
    src =
      lib.sourceByRegex
        (
          fetchFromGitHub {
            owner = "Chris-F5";
            repo = "kakoune";
            rev = "3a86757c65d3241411c47a06bd854265d71e10b2"; # branch=lean-squashed
            hash = "sha256-ubAaHgmpA0OnjSlB7dvEm2y91vEuJreVmn+ED02P8Sw=";
          }
          + "/rc/filetype"
        )
        [
          "^lean\\.kak$"
          "^lean-abbreviations\\.pl$"
          "^lean_abbreviations\\.json$"
        ];
    nativeBuildInputs = [ sd ];
    postInstall = ''
      sd -F 'perl "$kak_runtime/rc/filetype/lean-abbreviations.pl" "$kak_runtime/rc/filetype/lean_abbreviations.json"' \
        "${lib.getExe perlJSON} '$target/lean-abbreviations.pl' '$target/lean_abbreviations.json'" "$target/lean.kak"
    '';
  };

  lsp.languageServers.lean4 = {
    # The lean lsp server ignores the rootUri set in the LSP initialization
    # options. Instead, we must ensure that the cwd is in the workspace root.
    args = [
      "-c"
      ''
        kak_buffile=%val{buffile}
        %opt{lsp_find_root} lakefile.lean lakefile.toml .git .hg >/dev/null
        exec lake serve
      ''
    ];
    package = elan;
    command = "sh";
    filetypes = [ "lean" ];
    roots = [
      "lakefile.lean"
      "lakefile.toml"
      ".git"
      ".hg"
    ];
  };
}
