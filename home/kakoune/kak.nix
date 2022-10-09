{ config, pkgs, lib, ... }:

let
  kakounePkg =
    pkgs.kakoune.override {
      kakoune = pkgs.kakoune-unwrapped.overrideAttrs (oldAttrs: {
        version = "r${builtins.substring 0 6 pkgs.sources.kakoune.rev}";
        src = pkgs.sources.kakoune;
      });
    };

  kak-lsp = pkgs.libs.crane.buildPackage {
    src = pkgs.sources.kak-lsp;
    buildInputs = (with pkgs;
      lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Security SystemConfiguration ])
    ) ++ (with pkgs; [ libiconv ]
    );
  };

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
  programs.kak-lsp.languages.scala = {
    command = "metals";
    filetypes = [ "scala" ];
    roots = [ "build.sbt" ];
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
            executable = "${pkgs.zathura}/bin/zathura";
            args = [ "--synctex-forward" "%l:1:%f" "%p" "-x" "/home/nki/.bin/kaktex jump %{input} %{line}" ];
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
      name = "luar";
      src = pkgs.fetchFromGitHub {
        owner = "gustavo-hms";
        repo = "luar";
        rev = "2f430316f8fc4d35db6c93165e2e77dc9f3d0450";
        sha256 = "sha256-vHn/V3sfzaxaxF8OpA5jPEuPstOVwOiQrogdSGtT6X4=";
      };
      activationScript = ''
        # Enable luar
        require-module luar
        # Use luajit
        set-option global luar_interpreter ${pkgs.luajit}/bin/luajit
      '';
    }
    {
      name = "peneira";
      src = pkgs.fetchFromGitHub {
        owner = "natsukagami";
        repo = "peneira";
        rev = "743b9971472853a752475e7c070ce99089c6840c";
        sha256 = "sha256-E4ndbF9YC1p0KrvSuGgwmG1Y2IGTuGKJo/AuMixhzlM=";
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
      name = "kakoune-focus";
      src = pkgs.fetchFromGitHub {
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
      src = pkgs.fetchFromGitLab {
        owner = "Screwtapello";
        repo = "kakoune-inc-dec";
        rev = "7bfe9c51";
        sha256 = "0f33wqxqbfygxypf348jf1fiscac161wf2xvnh8zwdd3rq5yybl0";
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
    rec {
      name = "kakoune-mirror";
      src = pkgs.fetchFromGitHub
        {
          owner = "Delapouite";
          repo = "kakoune-mirror";
          rev = "5710635f440bcca914d55ff2ec1bfcba9efe0f15";
          sha256 = "sha256-uslx4zZhvjUylrPWvTOugsKYKKpF0EEz1drc1Ckrpjk=";
        } + "/mirror.kak";
      wrapAsModule = true;
      activationScript = ''
        require-module ${name}

        # Bind <a-w> to ${name}
        map global normal <a-w> ': enter-user-mode -lock mirror<ret>'
      '';
    }
    {
      name = "unicode-math";
      src = pkgs.fetchFromGitHub {
        owner = "natsukagami";
        repo = "kakoune-unicode-math";
        rev = "75b25c507234addd6e56f7cbd9b913357c322004";
        # sha256 = lib.fakeSha256;
        sha256 = "sha256-MG0jzFBVudEjQ2OIBr+MipYjXCvWFSk1q+q8YsO4jLo=";
        fetchSubmodules = true;
      };
      activationScript = ''
        require-module unicode-math

        # Bind <c-s> to the menu
        map global insert <c-s> '<a-;>: insert-unicode '
      '';
    }
  ];
}

