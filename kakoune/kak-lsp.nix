{ config, pkgs, lib, ... }:

let
    rev = "5bcb2a5fad27bc2871cc3fb0d15e5c7c1074d8b9";
    version = "r${builtins.substring 0 6 rev}";

    kak-lsp = pkgs.kak-lsp.overrideAttrs (drv: rec {
        inherit rev version;
        buildInputs = drv.buildInputs ++
            (with pkgs; lib.optional stdenv.isDarwin darwin.apple_sdk.frameworks.SystemConfiguration);
        src = pkgs.fetchFromGitHub {
            owner = "kak-lsp";
            repo = "kak-lsp";
            rev = rev;
            sha256 = "1j6mdcg6zrbirmy5n1zbin5h8jn1m2xxy8chsdwgmaw7mj8d527z";
        };

        cargoDeps = drv.cargoDeps.overrideAttrs (lib.const {
            inherit src;
            outputHash = (
                if pkgs.stdenv.isDarwin
                then "1risazihwy6v3rc1lxram0z2my29b3w52d827963b7zfahgmsaq5"
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
