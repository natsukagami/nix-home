{ config, pkgs, lib, ... }:

let
  fd =
    if pkgs.stdenv.isAarch64 && pkgs.stdenv.isLinux then
      pkgs.fd.overrideAttrs
        (attrs:
          {
            preBuild = ''
              export JEMALLOC_SYS_WITH_LG_PAGE=16
            '';
          }) else pkgs.fd;
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
    ## Python
    python3

    # Fonts
    fantasque-sans-mono
    ## Enable the FSM font with NF variant
    (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # CLI tools
    fd
    ripgrep
    fossil
    openssh
    ## File Manager
    nnn
    ## PDF Processors
    poppler_utils
    ## htop replacement
    htop-vim
    ## Bitwarden
    rbw

    ## To do tunneling with cloudflare
    pkgs.cloudflared

    # Databases
    postgresql
    mariadb

    # Docker, because it's useful ...sometimes
    docker
  ];

  home.sessionVariables = {
    # Bat theme
    BAT_THEME = "GitHub";
    # Editor
    EDITOR = "kak";
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
