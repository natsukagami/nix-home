{ config, pkgs, ... }:

{
    programs.fish = {
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

    # Source files
    home.file = {
        "fish/change_cmd.fish" = {
            source = ./. + "/change_cmd.fish";
            target = ".config/fish/change_cmd.fish";
        };
    };
}
