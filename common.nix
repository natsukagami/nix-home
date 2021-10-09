{ config, pkgs, ... }:

{
    imports = [
      ./kakoune/kak.nix
      ./fish/fish.nix
    ];

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Enable the manual so we don't have to load it
    manual.html.enable = true;

    # Packages that are not in programs section
    home.packages = with pkgs; [
      # Build Tools
      ## C++
      autoconf
      automake
      ## SQL
      flyway
      ## Go
      go # to be configured later
      ## Rust
      rust-analyzer
      ## JavaScript
      yarn

      # Fonts
      fantasque-sans-mono

      # CLI tools
      fd
      fossil
      ## Blog generator
      hugo
      ## File Manager
      nnn
      ## PDF Processors
      poppler_utils
      ## htop replacement
      bottom

      # Databases
      postgresql
    ];

    home.sessionVariables = {
      # Bat theme
      BAT_THEME = "GitHub";
    };

    home.sessionPath = [
      # Sometimes we want to install custom scripts here
      "~/.local/bin"
    ];

    # Programs
    programs = {
        bat = {
            enable = true;
            config = {
                theme = "GitHub";
            };
        };

        broot.enable = true;

        command-not-found.enable = true;

        exa = {
            enable = true;
            enableAliases = true;
        };

        # later
        firefox = {};

        fzf = {
            enable = true;
            enableFishIntegration = true;
        };

        gh = {
            enable = true;
            gitProtocol = "ssh";
        };

        git = {
            enable = true;
            delta = {
                enable = true;
                options = {
                    line-numbers = true;
                    side-by-side = true;
                };
            };
            signing.key = null;
            signing.signByDefault = true;
            userEmail = "nki@nkagami.me";
            userName = "Natsu Kagami";
            extraConfig = {
                init.defaultBranch = "master";
            };
        };

        gpg.enable = true;

        jq.enable = true;

        nushell.enable = true;
    };
}
