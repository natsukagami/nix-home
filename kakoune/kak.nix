{ config, pkgs, ... }:

let
    kakounePkg =
        let
            rev = "85a1f78ca989cc25a34b6ece812682b287e9c944";
        in
        pkgs.kakoune.override {
            kakoune = pkgs.kakoune-unwrapped.overrideAttrs (oldAttrs : {
                version = "r${builtins.substring 0 6 rev}";
                src = pkgs.fetchFromGitHub {
                    repo = "kakoune";
                    owner = "mawww";
                    rev = rev;
                    sha256 = "13kc68vkrzg89khir6ayyxgbnmz16dhippcnw09hhzxivf5ayzpy";
                };
            });
        };

    # record a file in the kakoune folder
    kakouneFile = filename : {
        name = "kakoune/${filename}";
        value = {
            source = ./. + "/${filename}";
            target = ".config/kak/${filename}";
        };
    };

    kakouneAutoload = { name, src } : {
        name = "kakoune/autoload/${name}";
        value = {
            source = src;
            target = ".config/kak/autoload/${name}";
        };
    };
in
{
    # Enable the kakoune package.
    home.packages = [ kakounePkg ];

    # Source the kakrc we have here.
    home.file = builtins.listToAttrs (map kakouneFile [
        "kakrc"
        "latex.kak"
        "racket.kak"
        "source-pwd"

        # autoload files
        "autoload/markdown.kak"
    ] ++ map kakouneAutoload [
        # include the original autoload files
        {
            name = "rc";
            src = "${kakounePkg}/share/kak/autoload";
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
                sha256 = "0cxmk4yiy30lxd3h02g02b1d9pds2pa46p3pvamj9wwq9sai5xdi";
                leaveDotGit = true;
            };
        }
    ]);
}
