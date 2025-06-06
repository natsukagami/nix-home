{
  callPackage,
  utils ? callPackage ./utils.nix { },
  fetchFromGitHub,
  fetchFromGitLab,
  luajit,
  ...
}:
with {
  inherit (utils) toDir writeModuleWrapper kakounePlugin;
};
builtins.map kakounePlugin [
  # My own scripts
  {
    name = "latex.kak";
    src = toDir "latex.kak" ./autoload/latex.kak;
  }
  {
    name = "markdown.kak";
    src = toDir "markdown.kak" ./autoload/markdown.kak;
  }

  # Plugins
  {
    name = "luar";
    src = fetchFromGitHub {
      owner = "gustavo-hms";
      repo = "luar";
      rev = "2f430316f8fc4d35db6c93165e2e77dc9f3d0450";
      sha256 = "sha256-vHn/V3sfzaxaxF8OpA5jPEuPstOVwOiQrogdSGtT6X4=";
    };
    activationScript = ''
      # Enable luar
      require-module luar
      # Use luajit
      set-option global luar_interpreter ${luajit}/bin/luajit
    '';
  }
  {
    name = "peneira";
    src = fetchFromGitHub {
      owner = "gustavo-hms";
      repo = "peneira";
      rev = "b56dd10bb4771da327b05a9071b3ee9a092f9788";
      sha256 = "sha256-rZBZ+ks9aaefmjl6GAAwg/HQqDbMEp+zkevMbJ1QeUI=";
    };
    activationScript = ''
      require-module peneira

      # Change selection color
      set-face global PeneiraSelected @PrimarySelection

      # Buffers list
      define-command -hidden peneira-buffers %{
          peneira 'buffers: ' %{ printf '%s\n' $kak_quoted_buflist } %{
              buffer %arg{1}
          }
      }

      # Grep in the current location
      define-command peneira-grep %{
        peneira 'line: ' %{ rg -n . . } %{
          lua %arg{1} %{
            local file, line = arg[1]:match("([^:]+):(%d+):")
            kak.edit(file, line)
          }
        }
      }

      # A peneira menu
      declare-user-mode fuzzy-match-menu

      map -docstring "Switch to buffer"                            global fuzzy-match-menu b ": peneira-buffers<ret>"
      map -docstring "Symbols"                                     global fuzzy-match-menu s ": peneira-symbols<ret>"
      map -docstring "Lines"                                       global fuzzy-match-menu l ": peneira-lines<ret>"
      map -docstring "Lines in the current directory"              global fuzzy-match-menu g ": peneira-grep<ret>"
      map -docstring "Files in project"                            global fuzzy-match-menu f ": peneira-files<ret>"
      map -docstring "Files in currently opening file's directory" global fuzzy-match-menu F ": peneira-local-files<ret>"

      # Bind menu to user mode
      map -docstring "Fuzzy matching" global user f ": enter-user-mode fuzzy-match-menu<ret>"
    '';
  }
  {
    name = "kakoune-focus";
    src = fetchFromGitHub {
      owner = "caksoylar";
      repo = "kakoune-focus";
      rev = "949c0557cd4c476822acfa026ca3c50f3d38a3c0";
      sha256 = "sha256-ZV7jlLJQyL420YG++iC9rq1SMjo3WO5hR9KVvJNUiCs=";
    };
    activationScript = ''
      map global user <space> ': focus-toggle<ret>' -docstring "toggle selections focus"
    '';
  }
  {
    name = "kakoune-inc-dec";
    src = fetchFromGitLab {
      owner = "Screwtapello";
      repo = "kakoune-inc-dec";
      rev = "7bfe9c51";
      sha256 = "0f33wqxqbfygxypf348jf1fiscac161wf2xvnh8zwdd3rq5yybl0";
    };
  }
  {
    name = "racket.kak";
    src =
      (builtins.fetchTree {
        type = "git";
        url = "https://bitbucket.org/KJ_Duncan/kakoune-racket.kak.git";
        rev = "e397042009b46916ff089d79166ec0e8ca813a18";
        narHash = "sha256-IcxFmvG0jqpMCG/dT9crVRgPgMGKkic6xwrnW5z4+bc=";
      })
      + "/rc";
  }
  rec {
    name = "kakoune-mirror";
    src =
      fetchFromGitHub {
        owner = "Delapouite";
        repo = "kakoune-mirror";
        rev = "5710635f440bcca914d55ff2ec1bfcba9efe0f15";
        sha256 = "sha256-uslx4zZhvjUylrPWvTOugsKYKKpF0EEz1drc1Ckrpjk=";
      }
      + "/mirror.kak";
    wrapAsModule = true;
    activationScript = ''
      require-module ${name}

      # Bind <a-w> to ${name}
      map global normal <a-w> ': enter-user-mode -lock mirror<ret>'
    '';
  }
  {
    name = "unicode-math";
    src = fetchFromGitHub {
      owner = "natsukagami";
      repo = "kakoune-unicode-math";
      rev = "08dff25da2b86ee0b0777091992bc7fb28c3cb1d";
      # sha256 = lib.fakeSha256;
      sha256 = "sha256-j0L1ARex1i2ma8sGLYwgkfAbh0jWKh/6QGHFaxPXIKc=";
      fetchSubmodules = true;
    };
    activationScript = ''
      require-module unicode-math

      # Bind <c-s> to the menu
      map global insert <c-s> '<a-;>: insert-unicode '
    '';
  }
  {
    name = "kakoune-buffers";
    src = fetchFromGitHub {
      owner = "Delapouite";
      repo = "kakoune-buffers";
      rev = "6b2081f5b7d58c72de319a5cba7bf628b6802881";
      sha256 = "sha256-jOSrzGcLJjLK1GiTSsl2jLmQMPbPxjycR0pwF5t/eV0=";
    };
    activationScript = ''
      # Suggested hook

      hook global WinDisplay .* info-buffers

      # Suggested mappings

      map global user b ':enter-buffers-mode<ret>'              -docstring 'buffers…'
      map global normal ^ ':enter-buffers-mode<ret>'              -docstring 'buffers…'
      map global user B ':enter-user-mode -lock buffers<ret>'   -docstring 'buffers (lock)…'

      # Suggested aliases

      alias global bd delete-buffer
      alias global bf buffer-first
      alias global bl buffer-last
      alias global bo buffer-only
      alias global bo! buffer-only-force
    '';
  }
]
