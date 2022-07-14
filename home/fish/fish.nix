{ config, pkgs, ... }:

{
  imports = [
    ./tide/nix-shell.nix
  ];

  home.packages = [ pkgs.timg ];

  programs.fish = {
    enable = true;
    package = pkgs.unstable.fish;
    functions = { };

    tide = {
      nix-shell.enable = true;
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

    shellInit = ''
      # Source brew integration
      if test -e /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv | source
      end
    '';

    interactiveShellInit = ''
      function fish_greeting
        ${pkgs.timg}/bin/timg ${./arona.jpg}
        printf (env LANG=ja_JP.UTF-8 date +"ご主人様、お帰りなさい！\n今日は%A、%Y年%m月%d日ですねー！今の時間って、%H時%M分です〜 \n言って言ってご主人様、コンピュターちゃんと何がするつもりでしょーか？〜エヘヘっ\n")
      end

      # Set up an editor alias
      if test -n "$EDITOR"
          alias e="$EDITOR"
      else
          alias e="kak"
      end

      # Source iTerm2 integration
      if test -e ~/.iterm2_shell_integration.fish; and test $__CFBundleIdentifier = "com.googlecode.iterm2"
        source ~/.iterm2_shell_integration.fish
      end

      # Source Kitty integration
      if set -q KITTY_INSTALLATION_DIR
        set --global KITTY_SHELL_INTEGRATION enabled
        source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"

        # Add fish to PATH if installed as a MacOS App
        test -e $KITTY_INSTALLATION_DIR/../../MacOS && set -x PATH $PATH "$KITTY_INSTALLATION_DIR/../../MacOS"
      end

      # Enable vi keybindings
      fish_vi_key_bindings
      ## Set some kak-focused keybindings
      bind -M default gi beginning-of-line
      bind -M default gl end-of-line

      # Set up direnv
      ${pkgs.direnv}/bin/direnv hook fish | source
    '';
    plugins = [
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "3787c725f7f6a0253f59a2c0e9fde03202689c6c";
          sha256 = "00zsib1q21bgxffjlyxf5rgcyq3h1ixwznwvid9k6mkkmwixv9lj";
        };
      }
      {
        name = "fzf";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "fzf";
          rev = "479fa67d7439b23095e01b64987ae79a91a4e283";
          sha256 = "0k6l21j192hrhy95092dm8029p52aakvzis7jiw48wnbckyidi6v";
        };
      }
    ];
  };

  # Source files
  home.file = {
    "fish/change_cmd.fish" = {
      source = ./. + "/change_cmd.fish";
      target = ".config/fish/conf.d/change_cmd.fish";
    };
    "fish/pls.fish" = {
      source = ./. + "/pls.fish";
      target = ".config/fish/conf.d/pls.fish";
    };
  };
}
