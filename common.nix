{ config, pkgs, ... }:

{

  # Enable the manual so we don't have to load it
  manual.html.enable = true;

  # Packages that are not in programs section
  home.packages = with pkgs; [
      # Build tools
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

      # Databases
      postgresql

  ];

  # Programs
  programs = {
      bat = {
          enable = true;
          config = {
              theme = "GitHub";
          };
      };

      bottom.enable = true;

      command-not-found.enable = true;

      exa = {
          enable = true;
      };

      # later
      firefox = {};

      fish = {
          enable = true;
          functions = {
          };

          shellAliases = {
              cat = "bat --theme=GitHub ";
              l = "exa -l --color=always ";
              htop = "btm --color nord-light -b --tree";
              Htop = "btm --color nord-light --tree";

              # My own commands for easy access
              thisterm = "cd ~/Projects/uw/$CURRENT_TERM";
              today = "date +%F";
          };

          interactiveShellInit = ''
            set fish_greeting

            # Set up an editor alias
            if test -n "$EDITOR"
                alias e="$EDITOR"
            else
                alias e="kak"
            end

            # sudo => pls
            source ~/.config/fish/pls.fish

            # set up change_cmd
            source ~/.config/fish/change_cmd.fish


            # Load completion for github
            gh completion --shell fish | source

            # Bitwarden
            source ~/.config/fish/bw.fish

            # Source iTerm2 integration
            source ~/.iterm2_shell_integration.fish
          '';
          plugins = [
            {
                name = "tide";
                src = pkgs.fetchFromGitHub {
                    owner = "IlanCosman";
                    repo  = "tide";
                    rev   = "3787c725f7f6a0253f59a2c0e9fde03202689c6c";
                    sha256 = "00zsib1q21bgxffjlyxf5rgcyq3h1ixwznwvid9k6mkkmwixv9lj";
                };
            }
            {
                name = "fzf";
                src = pkgs.fetchFromGitHub {
                    owner = "jethrokuan";
                    repo  = "fzf";
                    rev   = "479fa67d7439b23095e01b64987ae79a91a4e283";
                    sha256 = "0k6l21j192hrhy95092dm8029p52aakvzis7jiw48wnbckyidi6v";
                };
            }
          ];
      };

      fzf = {
          enable = true;
          enableFishIntegration = true;
      };

      gh = {
          enable = true;
          gitProtocol = "ssh";
      };

      jq.enable = true;

      nushell.enable = true;
  };
}
