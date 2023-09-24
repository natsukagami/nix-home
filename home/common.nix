{ config, pkgs, lib, ... }:

let
  texlab = pkgs.unstable.texlab;
in
{
  imports = [
    ./kakoune/kak.nix
    ./fish/fish.nix
    ./modules/programs/my-broot.nix
    ./modules/programs/my-sway
    ./modules/programs/my-kitty
    ./modules/programs/openconnect-epfl.nix
    ./common-linux.nix

    # PATH Overrides
    ({ config, lib, ... }: {
      home.sessionPath = lib.mkBefore [
        "${config.home.homeDirectory}/.bin/overrides"
      ];
    })
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
    ## Nix
    cachix
    rnix-lsp
    ## Latex
    tectonic
    texlab
    ## Typst
    typst
    ## Python
    python3
    ## Scala
    pkgs.unstable.scala-cli

    # Fonts
    fantasque-sans-mono
    ## Get the nerd font symbols
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })

    # CLI tools
    fd
    ripgrep
    fossil
    openssh
    tea # gitea CLI (gh-like)
    fx # JSON viewer
    glow # Markdown viewer
    ## File Manager
    nnn
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

    ## To do tunneling with cloudflare
    pkgs.cloudflared

    # Databases
    postgresql
    mariadb
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

    exa = {
      enable = true;
      enableAliases = true;
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
      };
    };

    gpg.enable = true;

    jq.enable = true;

    nushell.enable = true;
  };
}
