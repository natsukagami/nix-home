{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./kakoune.nix
    ./fish/fish.nix
    ./modules/programs/my-broot.nix
    ./modules/programs/my-waybar.nix
    ./modules/programs/my-sway
    ./modules/programs/my-niri.nix
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
    # TeX
    texlive.combined.scheme-full
    inkscape # for TeX svg
    ## htop replacement
    htop-vim
    nmon
    ## Bitwarden
    rbw
    ## File compression stuff
    ouch

    distrobox
  ];
  home.file.".latexmkrc".text = ''
    $pdf_previewer = '${lib.getExe' pkgs.xdg-utils "xdg-open"}';
  '';

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
      userEmail = "nki@nkagami.me";
      userName = "Natsu Kagami";
      signing = {
        format = "ssh";
        key = "~/.ssh/nki@nkagami.me";
        signByDefault = true;
      };
      extraConfig = {
        init.defaultBranch = "master";
        core.excludesFile = "${pkgs.writeText ".gitignore" ''
          .direnv
          .envrc
          .kakrc
        ''}";
        commit.verbose = true;
        safe.directory = "*";
        merge.conflictstyle = "zdiff3";
      };
    };

    gpg.enable = true;

    jq.enable = true;

    nushell.enable = true;
  };
}
