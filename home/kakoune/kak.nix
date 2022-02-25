{ config, pkgs, lib, ... }:

let
  kakounePkg =
    let
      rev = "d44d07bd801a939de65e5c237f65b54c187143c1";
    in
    pkgs.kakoune.override {
      kakoune = pkgs.kakoune-unwrapped.overrideAttrs (oldAttrs: {
        version = "r${builtins.substring 0 6 rev}";
        src = pkgs.fetchFromGitHub {
          repo = "kakoune";
          owner = "mawww";
          rev = rev;
          sha256 = "sha256-32WTy5qQgg9Sly86KZcO0gEaHTfHUSNAT+E5+JnHkr8=";
          # sha256 = lib.fakeSha256;
        };
      });
    };

  evince-synctex = (pkgs.fetchFromGitHub {
    owner = "latex-lsp";
    repo = "evince-synctex";
    rev = "593b00c938d82786b8bbaf584ebe68744f9c8407";
    sha256 = "sha256-Q9kZ/XmXEsoZpflF5n16I5bsyS2S8gS9OYkOPM47ryg=";
  }) + "/evince_synctex.py";

  kak-lsp =
    let
      rev = "v12.0.1";
      # version = "r${builtins.substring 0 6 rev}";
      version = rev;
    in
    pkgs.kak-lsp.overrideAttrs (drv: rec {
      inherit rev version;
      buildInputs = drv.buildInputs ++
        (with pkgs; lib.optional stdenv.isDarwin darwin.apple_sdk.frameworks.SystemConfiguration);
      src = pkgs.fetchFromGitHub {
        owner = "kak-lsp";
        repo = "kak-lsp";
        rev = rev;
        sha256 = "sha256-K2GMoLaH7D6UtPuL+GJMqsPFwriyyi7WMdfzBmOceSA=";
        # sha256 = lib.fakeSha256;
      };

      cargoDeps = drv.cargoDeps.overrideAttrs (lib.const {
        inherit src;
        outputHash = "sha256-G7X/dZTryNlwY9n02LL/3yVpB2L1vWGx/lqYblFDAOM=";
        # outputHash = lib.fakeSha256;
      });
    });
in
{
  imports = [ ../modules/programs/my-kakoune ./kaktex.nix ];

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
        } else {
          executable = "${evince-synctex}";
          args = [ "-f" "%l" "%p" "\"${config.home.file.kaktex.source} jump %f %l\"" ];
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
      name = "fzf.kak";
      src = pkgs.fetchFromGitHub {
        owner = "andreyorst";
        repo = "fzf.kak";
        rev = "68f21eb78638e5a55027f11aa6cbbaebef90c6fb";
        sha256 = "12zfvyxqgy18l96sg2xng20vfm6b9py6bxmx1rbpbpxr8szknyh6";
      };
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
  ];
}
