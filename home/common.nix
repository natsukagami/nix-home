{ config, pkgs, lib, ... }:

{
  imports = [
    ./kakoune/kak.nix
    ./fish/fish.nix
    ./modules/programs/my-broot.nix
    ./modules/programs/my-sway
    ./modules/programs/my-kitty
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
    python310

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

    ## To do tunneling with cloudflare
    pkgs.unfree.cloudflared

    # Databases
    postgresql
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

  nki.programs.kitty.enable = true;

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

    # later
    firefox = { };

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
