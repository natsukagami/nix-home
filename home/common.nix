{ config, pkgs, ... }:

{
  imports = [
    ./kakoune/kak.nix
    ./fish/fish.nix
    ./modules/programs/my-broot.nix
    ./modules/programs/my-waybar.nix
    ./modules/programs/my-sway
    ./modules/programs/my-kitty
    ./modules/programs/openconnect-epfl.nix
    ./common-linux.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Temporarily disable the manuals
  manual.html.enable = false;
  # manual.manpage.enable = false;

  # Packages that are not in programs section
  home.packages = with pkgs; [
    # CLI tools
    fd
    sd
    ripgrep
    openssh
    tea # gitea CLI (gh-like)
    glab # gitlab CLI
    fx # JSON viewer
    glow # Markdown viewer
    nix-output-monitor # Nice nix output formatting
    unstable.scala-next
    ## PDF Processors
    poppler_utils
    ## htop replacement
    htop-vim
    ## Bitwarden
    rbw
    ## File compression stuff
    zip
    unzip
    zstd
    atool
  ];

  home.sessionVariables = {
    # Bat theme
    BAT_THEME = "GitHub";
    # Editor
    EDITOR = "kak";
  };

  home.sessionPath = [
    # Sometimes we want to install custom scripts here
    "${config.home.homeDirectory}/.local/bin"
  ];

  # Programs
  programs = {
    bat = {
      enable = true;
      config = {
        theme = "GitHub";
      };
    };

    my-broot.enable = true;

    direnv.enable = true;
    direnv.nix-direnv.enable = true;
    direnv.config.global.load_dotenv = true;

    eza = {
      enable = true;
      enableFishIntegration = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = true;
    };

    gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };

    git = {
      enable = true;
      delta = {
        enable = true;
        options = {
          line-numbers = true;
        };
      };
      signing.key = "0x55A032EB38B49ADB";
      signing.signByDefault = true;
      userEmail = "nki@nkagami.me";
      userName = "Natsu Kagami";
      extraConfig = {
        init.defaultBranch = "master";
        core.excludesFile = "${pkgs.writeText ".gitignore" ''
          .direnv
          .envrc
          .kakrc
        ''}";
        safe.directory = "*";
        merge.conflictstyle = "zdiff3";
      };
    };

    gpg.enable = true;

    jq.enable = true;

    nushell.enable = true;
  };
}
