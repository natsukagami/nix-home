{ config, pkgs, lib, ... }:

let
  kakounePkg =
    let
      rev = "f68e8313b2282b1a94bd5baee2b87581f31fc5e8";
    in
    pkgs.kakoune.override {
      kakoune = pkgs.kakoune-unwrapped.overrideAttrs (oldAttrs: {
        version = "r${builtins.substring 0 6 rev}";
        src = pkgs.fetchFromGitHub {
          repo = "kakoune";
          owner = "mawww";
          rev = rev;
          sha256 = "sha256-CvOjNB30FlN41JZEVuLQhYLy7D8M2BeQBnQ1S+oel5w=";
          # sha256 = lib.fakeSha256;
        };
      });
    };
in
{
  imports = [ ../modules/programs/my-kakoune ];
  
  # Enable the kakoune package.
  programs.my-kakoune.enable = true;
  programs.kak-lsp.enable = true;

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
