{
  elan,
  python3,
  fetchFromGitHub,
  util,
  ...
}:
{
  plugin = util.kakounePlugin {
    name = "lean4.kak";
    src = fetchFromGitHub {
      owner = "Lqnk4";
      repo = "lean4.kak";
      rev = "5c2696fd7716c15ccf3fa84322fd291f427e16f2";
      hash = "sha256-Gy6PDuei8d5R8uzV493dn/oo14LFiAJd+oih0POIFXo=";
    };
  };

  extraPackages = [ python3 ];

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
