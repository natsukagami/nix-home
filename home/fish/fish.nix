{
  config,
  options,
  pkgs,
  lib,
  ...
}:

with lib;
let
  bootDesktop = pkgs.writeScriptBin "boot-desktop" ''
    #!/usr/bin/env fish

    set -a PATH ${pkgs.gum}/bin

    set GUM_CHOOSE_HEADER "Select the Desktop to boot into:"
    set CHOICES

    if which niri-session &>/dev/null
      set -a CHOICES "Niri"
    end
    if which sway &>/dev/null
      set -a CHOICES "sway"
    end
    if which startplasma-wayland &>/dev/null
      set -a CHOICES "KDE Plasma"
    end
    set -a CHOICES "None: continue to shell"

    set PREVIOUS_CHOICE_FILE ~/.local/state/last_desktop

    while test -z "$CHOICE"
      set PREVIOUS_CHOICE (cat $PREVIOUS_CHOICE_FILE 2>/dev/null || echo)
      set CHOICE (gum choose --selected=$PREVIOUS_CHOICE --header=$GUM_CHOOSE_HEADER $CHOICES)
    end

    echo $CHOICE > $PREVIOUS_CHOICE_FILE
    switch $CHOICE
      case "Niri"
        systemctl --user set-environment XDG_MENU_PREFIX=plasma-
        exec niri-session
      case "sway"
        systemctl --user unset-environment NIXOS_OZONE_WL
        exec sway
      case "KDE Plasma"
        exec ${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed startplasma-wayland
      case '*'
        exec fish -i
    end
  '';
in
{
  imports = [
    ./tide
  ];

  options.programs.fish.everywhereAbbrs = mkOption {
    type = types.attrsOf types.str;
    description = "Abbreviations that expands everywhere";
    default = { };
  };

  config.home.packages = with pkgs; [
    timg
    # For fzf.fish
    fzf
    fd
    bat

    bootDesktop
  ];

  config.programs.fish = {
    enable = true;
    functions = {
      rebuild = {
        body = ''
          pls nixos-rebuild --flake ~/.config/nixpkgs -L --log-format internal-json -v $argv \
            &| ${pkgs.nix-output-monitor}/bin/nom --json
        '';
        wraps = "nixos-rebuild";
      };
      # Simplify nix usage!
      nx = {
        body = ''
          argparse -s 'h/help' 'impure' 'u/unstable' 'g/git' -- $argv
          if set -q _flag_help || test (count $argv) -eq 0
            echo "nx [--impure] [-u/--unstable/-g/--git] {package} [args...]"
            return 1
          else
            set -q _flag_impure && set impure "--impure"
            set nixpkgs "nixpkgs"
            set -q _flag_unstable && set nixpkgs "nixpkgs-unstable"
            set -q _flag_git && set nixpkgs "github:nixOS/nixpkgs/nixpkgs-unstable"
            nix run $impure $nixpkgs"#"$argv[1] -- $argv[2..]
          end
        '';
        description = "Runs an app from the nixpkgs store.";
      };

      nsh = {
        description = "Spawns a shell from the given nixpkgs packages";
        wraps = "nix shell";
        body = ''
          function help
            echo "nsh [--impure] [--impure] [-u/--unstable/-g/--git] {package}* [-c command args...]"
          end
          argparse -s 'h/help' 'impure' 'u/unstable' 'g/git' -- $argv
          if set -q _flag_help || test (count $argv) -eq 0
            help
            return 0
          end
          set packages $argv
          set minusc (contains -i -- "-c" $argv)
          if test -n "$minusc"
            if test $minusc -eq 1
              help
              return 1
            end
            set packages $argv[..(math $minusc - 1)]
            set argv $argv[(math $minusc + 1)..]
          else
            set argv "fish" "-i"
          end
          if test (count $packages) -eq 0
            help
            return 1
          end
          set -q _flag_impure && set impure "--impure"
          set nixpkgs "nixpkgs"
          set -q _flag_unstable && set nixpkgs "nixpkgs-unstable"
          set -q _flag_git && set nixpkgs "github:nixOS/nixpkgs/nixpkgs-unstable"
          nix shell $impure $nixpkgs"#"$packages --command $argv
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
      echo-today = "date +%F";
      newfile = "for f in $argv; mkdir -p (dirname $f) && touch $f && printf 'New file %s created.\n' $f; end";

      # pls
      pls = {
        wraps = "sudo";
        body = ''
          set -l cmd "`"(string join " " -- $argv)"`"
          echo "I-It's not like I'm gonna run "$cmd" for you or a-anything! Baka >:C" >&2
          # Send a notification on password prompt
          if command sudo -vn 2>/dev/null
              # nothing to do, user already authenticated
          else
              # throw a notification
              set notif_id (kitten notify -P \
                -p ${./haruka.png} \
                -a "pls" \
                -u critical \
                "A-a command requires your p-password" \
                (printf "I-I need your p-password to r-run the following c-command:\n\n%s" $cmd))
              command sudo -v -p "P-password please: "
              kitten notify -i $notif_id ""
          end
          command sudo $argv
        '';
      };
    };

    tide = {
      enable = true;
      leftItems = options.programs.fish.tide.leftItems.default;
      rightItems = options.programs.fish.tide.rightItems.default;
    };

    shellAliases = {
      cat = "bat --theme=GitHub ";
      catp = "bat --theme=GitHub -p ";
      l = "exa -l --color=always ";
      e = "$EDITOR";
      "cp+" = "rsync -avzP";
    };

    everywhereAbbrs = {
      lsports = if pkgs.stdenv.isDarwin then "lsof -i -P | grep LISTEN" else "ss -tulp";
    };

    shellInit = ''
      # Source brew integration
      if test -e /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv | source
      end

      # Override PATH
      set --export --prepend PATH ~/.bin/overrides ~/.local/bin
    '';

    interactiveShellInit = ''
      # Sway!
      if status --is-login; and test -z $DISPLAY; and test (tty) = "/dev/tty1"
        exec ${lib.getExe bootDesktop}
      end

      function fish_greeting
        ${pkgs.timg}/bin/timg ${./arona.jpg}
        printf (env LANG=ja_JP.UTF-8 date +"ご主人様、お帰りなさい！\n今日は%A、%Y年%m月%d日ですねー！今の時間って、%H時%M分です〜 \n言って言ってご主人様、コンピュターちゃんと何がするつもりでしょーか？〜エヘヘっ\n")
      end

      functions --copy fish_title __original_fish_title
      functions --erase fish_title
      function fish_title
        echo (__original_fish_title) - fish
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

      # Everywhere abbrs
      ${concatStringsSep "\n" (
        mapAttrsToList (
          k: v: "abbr --add --position anywhere -- ${k} ${escapeShellArg v}"
        ) config.programs.fish.everywhereAbbrs
      )}

      # Replace today with actual today
      abbr --add --position anywhere today -f echo-today

      # Set up direnv
      # ${pkgs.direnv}/bin/direnv hook fish | source

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
    '';
    plugins = [
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
  config.home.file = {
    "fish/change_cmd.fish" = {
      source = ./. + "/change_cmd.fish";
      target = ".config/fish/conf.d/change_cmd.fish";
    };
    "fish/pls.fish" = {
      source = ./pls_extra.fish;
      target = ".config/fish/conf.d/pls_extra.fish";
    };
  };
}
