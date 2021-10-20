{ config, pkgs, lib, ... }:

let
    rev = "3586feab17000f6ef526b2f9f6a11e008512b3e8";
    version = "r${builtins.substring 0 6 rev}";

    kak-lsp = pkgs.kak-lsp.overrideAttrs (drv: rec {
        inherit rev version;
        buildInputs = drv.buildInputs ++
            (with pkgs; lib.optional stdenv.isDarwin darwin.apple_sdk.frameworks.SystemConfiguration);
        src = pkgs.fetchFromGitHub {
            owner = "kak-lsp";
            repo = "kak-lsp";
            rev = rev;
            sha256 = "sha256-eSqqmlyD103AitHHbgdUAc1SzDpba7jRAokt1Kr1xhM=";
        };

        cargoDeps = drv.cargoDeps.overrideAttrs (lib.const {
            inherit src;
            outputHash = (
                if pkgs.stdenv.isDarwin
                then "sha256-BStdH1TunzVMOgI1UfhYSfgqPqgqdxpYHtt4DuNXOuY="
                else "0ywb9489jrb5lsycxlxzrj2khkcjhvzxbb0ckbpwwvg11r4ds240"
            );
        });
    });
in
{
    home.packages = [ kak-lsp ];

    # Configurations
    home.file."kakoune/kak-lsp.toml" = {
        source = ./. + "/kak-lsp.toml";
        target = ".config/kak-lsp/kak-lsp.toml";
    };
}
