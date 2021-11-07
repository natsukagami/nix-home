{ config, pkgs, lib, ... }:

{
  imports = [
    ./kakoune/kak.nix
    ./fish/fish.nix
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

    # Fonts
    fantasque-sans-mono
    ## Enable the FSM font with NF variant
    (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # CLI tools
    fd
    ripgrep
    fossil
    ## Blog generator
    hugo
    ## File Manager
    nnn
    ## PDF Processors
    poppler_utils
    ## htop replacement
    bottom

    ## To do tunneling with cloudflare
    cloudflared

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

  # Programs
  programs = {
    bat = {
      enable = true;
      config = {
        theme = "GitHub";
      };
    };

    broot.enable = true;

    direnv.enable = true;
    direnv.nix-direnv.enable = true;
    direnv.nix-direnv.enableFlakes = true;

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
    } // (
      let
        protocol = "ssh";
      in
      if (config.home.stateVersion == "21.05") then
        { gitProtocol = "ssh"; }
      else
        { settings.git_protocol = protocol; }
    );

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
