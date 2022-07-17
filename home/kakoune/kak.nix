{ config, pkgs, lib, ... }:

let
  kakounePkg =
    pkgs.kakoune.override {
      kakoune = pkgs.kakoune-unwrapped.overrideAttrs (oldAttrs: {
        version = "r${builtins.substring 0 6 pkgs.sources.kakoune.rev}";
        src = pkgs.sources.kakoune;
      });
    };

  evince-synctex = (pkgs.fetchFromGitHub {
    owner = "latex-lsp";
    repo = "evince-synctex";
    rev = "593b00c938d82786b8bbaf584ebe68744f9c8407";
    sha256 = "sha256-Q9kZ/XmXEsoZpflF5n16I5bsyS2S8gS9OYkOPM47ryg=";
  }) + "/evince_synctex.py";

  kak-lsp =
    pkgs.unstable.rustPlatform.buildRustPackage
      rec {
        pname = "kak-lsp";
        version = "r${builtins.substring 0 6 pkgs.sources.kak-lsp.rev}";

        src = pkgs.sources.kak-lsp;

        cargoSha256 = "sha256-TIsuHHFNne79cFo6os6NgT61YMbMV/fKHta2qPRrRkU=";
        # cargoSha256 = lib.fakeSha256;

        buildInputs = (with pkgs;
          lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Security SystemConfiguration ])
        );

        meta = with lib; {
          description = "Kakoune Language Server Protocol Client";
          homepage = "https://github.com/kak-lsp/kak-lsp";
          license = with licenses; [ unlicense /* or */ mit ];
          maintainers = [ maintainers.spacekookie ];
        };
      };

  activationScript = text: pkgs.writeText "config.kak" ''
    hook global KakBegin .* %{
      ${text}
    }
  '';
in
{
  imports = [ ../modules/programs/my-kakoune ./kaktex.nix ];

  # ctags for peneira
  home.packages = [ pkgs.universal-ctags ];

  # Enable the kakoune package.
  programs.my-kakoune.enable = true;
  programs.my-kakoune.enable-fish-session = true;
  programs.kak-lsp.enable = true;
  programs.kak-lsp.package = kak-lsp;
  programs.kak-lsp.languages.typescript = {
    args = [ "--stdio" ];
    command = "typescript-language-server";
    filetypes = [ "typescript" ];
    roots = [ "package.json" ];
  };
  programs.kak-lsp.languages.latex = {
    command = "texlab";
    filetypes = [ "latex" ];
    roots = [ ".git" "main.tex" "all.tex" ];
    settings_section = "texlab";
    settings.texlab = {
      build.executable = "latexmk";
      build.args = [ "-pdf" "-shell-escape" "-interaction=nonstopmode" "-synctex=1" "%f" ];

      build.forwardSearchAfter = true;
      build.onSave = true;

      forwardSearch =
        (if pkgs.stdenv.isDarwin then {
          executable = "/Applications/Skim.app/Contents/SharedSupport/displayline";
          args = [ "-r" "-g" "%l" "%p" "%f" ];
        } else
          {
            executable = "${pkgs.qpdfview}/bin/qpdfview";
            args = [ "--unique" "%p#src:%f:%l:1" ];
          });
    };
  };

  programs.my-kakoune.package = kakounePkg;
  programs.my-kakoune.rc =
    builtins.readFile ./kakrc + ''

      # Source any settings in the current working directory,
      # recursive upwards
      evaluate-commands %sh{
          ${pkgs.writeScript "source-pwd" (builtins.readFile ./source-pwd)}
      }
    '';
  programs.my-kakoune.autoload = [
    # My own scripts
    {
      name = "latex.kak";
      src = ./autoload/latex.kak;
    }
    {
      name = "markdown.kak";
      src = ./autoload/markdown.kak;
    }

    # Plugins
    {
      name = "01-luar";
      src = pkgs.fetchFromGitHub {
        owner = "gustavo-hms";
        repo = "luar";
        rev = "2f430316f8fc4d35db6c93165e2e77dc9f3d0450";
        sha256 = "sha256-vHn/V3sfzaxaxF8OpA5jPEuPstOVwOiQrogdSGtT6X4=";
      };
    }
    {
      name = "02-luar-config.kak";
      src = activationScript ''
        # Enable luar
        require-module luar
        # Use luajit
        set-option global luar_interpreter ${pkgs.luajit}/bin/luajit
      '';
    }
    {
      name = "03-peneira";
      src = pkgs.fetchFromGitHub {
        owner = "natsukagami";
        repo = "peneira";
        rev = "743b9971472853a752475e7c070ce99089c6840c";
        sha256 = "sha256-E4ndbF9YC1p0KrvSuGgwmG1Y2IGTuGKJo/AuMixhzlM=";
      };
    }
    {
      name = "04-peneira-config.kak";
      src = activationScript ''
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
          peneira 'line: ' "rg -n ." %{
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
      name = "01-kakoune-focus";
      src = pkgs.fetchFromGitHub {
        owner = "caksoylar";
        repo = "kakoune-focus";
        rev = "949c0557cd4c476822acfa026ca3c50f3d38a3c0";
        sha256 = "sha256-ZV7jlLJQyL420YG++iC9rq1SMjo3WO5hR9KVvJNUiCs=";
      };
    }
    {
      name = "02-kakoune-focus-config.kak";
      src = activationScript ''
        map global user <space> ': focus-toggle<ret>' -docstring "toggle selections focus"
      '';
    }
    {
      name = "01-cargo.kak";
      src = pkgs.fetchFromGitHub {
        owner = "krornus";
        repo = "kakoune-cargo";
        rev = "784e9d412a1331c6d2f2da61621a694d3e2c4281";
        sha256 = "1as0jss2fjvx4cyi3d6b9wqknzcf4p4046i5lf0ds582zsa60nis";
      };
    }
    {
      name = "00-kakoune-mouvre"; # needs to load before cargo.kak
      src = pkgs.fetchFromGitHub {
        owner = "krornus";
        repo = "kakoune-mouvre";
        rev = "47e6f20027d16806097d0bbee72b54717bcebaca";
        sha256 = "14fp3p1d0m98rgdjaaik5g44f0fabr6w39np3cqdaxq1i8skq6xv";
      };
    }
    {
      name = "kakoune-inc-dec";
      src = pkgs.fetchFromGitLab {
        owner = "Screwtapello";
        repo = "kakoune-inc-dec";
        rev = "7bfe9c51";
        sha256 = "0f33wqxqbfygxypf348jf1fiscac161wf2xvnh8zwdd3rq5yybl0";
        # leaveDotGit = true;
      };
    }
    {
      name = "racket.kak";
      src = (builtins.fetchTree {
        type = "git";
        url = "https://bitbucket.org/KJ_Duncan/kakoune-racket.kak.git";
        rev = "e397042009b46916ff089d79166ec0e8ca813a18";
        narHash = "sha256-IcxFmvG0jqpMCG/dT9crVRgPgMGKkic6xwrnW5z4+bc=";
      }) + "/rc";
    }
    {
      name = "kakoune-discord";
      src = (builtins.getFlake "github:natsukagami/kakoune-discord/03f95e40d6efd8fd3de7bca31653d43de2dcfc5f").packages.${pkgs.system}.kakoune-discord-rc + "/rc";
    }
  ];
}

