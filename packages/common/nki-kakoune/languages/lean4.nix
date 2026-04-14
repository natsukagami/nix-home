{
  lib,
  elan,
  python3,
  fetchFromGitHub,
  applyPatches,
  sd,
  util,
  ...
}:
{
  plugin = util.kakounePlugin {
    name = "lean4.kak";
    src = applyPatches {
      src = fetchFromGitHub {
        owner = "Lqnk4";
        repo = "lean4.kak";
        rev = "5c2696fd7716c15ccf3fa84322fd291f427e16f2";
        hash = "sha256-Gy6PDuei8d5R8uzV493dn/oo14LFiAJd+oih0POIFXo=";
      };
      patches = [ ./lean4.kak-use-source.patch ];
    };
    nativeBuildInputs = [ sd ];
    postInstall = ''
      sd -F 'python $kak_config/lean4-replace-abbreviations.py' "${lib.getExe python3} $target/lean4-replace-abbreviations.py" "$target/lean4.kak"
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
