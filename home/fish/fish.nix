{ config, pkgs, lib, ... }:

{
  imports = [
    ./tide/nix-shell.nix
  ];

  home.packages = with pkgs; [
    timg
    # For fzf.fish
    fzf
    fd
    bat
  ];

  programs.fish = {
    enable = true;
    package = pkgs.unstable.fish;
    functions = {
      # Simplify nix usage!
      nx = {
        body = ''
          set impure
          if test $argv[1] = "--impure"
            set impure "--impure"
            set argv $argv[2..]
          end
          if test (count $argv) -gt 0
            nix run $impure nixpkgs#$argv[1] -- $argv[2..]
          else
            echo "nx [--impure] {package} [args...]"
            return 1
          end
        '';
        wraps = "nix run";
        description = "Runs an app from the nixpkgs store.";
      };

      nsh = {
        description = "Spawns a shell from the given nixpkgs packages";
        wraps = "nix shell";
        body = ''
          set impure
          if test $argv[1] = "--impure"
            set impure "--impure"
            set argv $argv[2..]
          end
          if test (count $argv) -gt 0
            set minusc (contains -i -- "-c" $argv)
            if test -z $minusc
              nix shell $impure nixpkgs#$argv -c fish
            else if test $minusc -eq (count $argv)
              echo "nsh [--impure] {packages} [-c command args...]"
              return 1
            else
              nix shell $impure nixpkgs#$argv[..(math $minusc - 1)] $argv[$minusc..]
            end
          else
            echo "nsh [--impure] {packages} [-c command args...]"
            return 1
          end
        '';
      };
      # Grep stuff
      eg = {
        body = ''
          if test (count $argv) -gt 0
            ${pkgs.ripgrep}/bin/rg --vimgrep $argv | e
          else
            echo "eg {ripgrep options}"
            return 1
          end
        '';
        wraps = "rg";
        description = "Search with ripgrep and put results into the editor";
      };
    };

    tide = {
      nix-shell.enable = true;
    };

    shellAliases = {
      cat = "bat --theme=GitHub ";
      catp = "bat --theme=GitHub -p ";
      l = "exa -l --color=always ";

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

      functions --copy fish_title __original_fish_title
      functions --erase fish_title
      function fish_title
        echo (__original_fish_title) - fish
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

      # Set up tty for GPG
      export GPG_TTY=(tty)

      # Set up fzf bindings
      fzf_configure_bindings --directory=\ct --processes=\cp

      # Perl stuff
      set -x PATH ${config.home.homeDirectory}/perl5/bin $PATH 2>/dev/null;
      set -q PERL5LIB; and set -x PERL5LIB ${config.home.homeDirectory}/perl5/lib/perl5:$PERL5LIB;
      set -q PERL5LIB; or set -x PERL5LIB ${config.home.homeDirectory}/perl5/lib/perl5;
      set -q PERL_LOCAL_LIB_ROOT; and set -x PERL_LOCAL_LIB_ROOT ${config.home.homeDirectory}/perl5:$PERL_LOCAL_LIB_ROOT;
      set -q PERL_LOCAL_LIB_ROOT; or set -x PERL_LOCAL_LIB_ROOT ${config.home.homeDirectory}/perl5;
      set -x PERL_MB_OPT --install_base\ \"${config.home.homeDirectory}/perl5\";
      set -x PERL_MM_OPT INSTALL_BASE=${config.home.homeDirectory}/perl5;

      # Sway!
      if status --is-login; and which sway >/dev/null; and test -z $DISPLAY; and test (tty) = "/dev/tty1"
        read -P "Press enter to start sway..."; and exec sway
      end
    '';
    plugins = [
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "447945d2cff8f70d5c791dd4eec8b322d37798dd";
          # sha256 = lib.fakeSha256;
          sha256 = "sha256-1c2E3UC3r9hPfijAQoZ/+4yXieFxC4+hkk7wUyr30NM=";
        };
      }
      {
        name = "fzf";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "v9.7";
          sha256 = "sha256-haNSqXJzLL3JGvD4JrASVmhLJz6i9lna6/EdojXdFOo=";
        };
      }
      {
        name = "fenv";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-foreign-env";
          rev = "b3dd471bcc885b597c3922e4de836e06415e52dd";
          sha256 = "sha256-3h03WQrBZmTXZLkQh1oVyhv6zlyYsSDS7HTHr+7WjY8=";
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
