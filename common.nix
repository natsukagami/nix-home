{ config, pkgs, ... }:

{
  imports = [
      ./kakoune/kak.nix
      ./fish/fish.nix
  ];

  # Enable the manual so we don't have to load it
  manual.html.enable = true;

  # Packages that are not in programs section
  home.packages = with pkgs; [
      # Build tools
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

      # Fonts
      fantasque-sans-mono

      # CLI tools
      fd
      fossil
      ## Blog generator
      hugo
      ## File Manager
      nnn
      ## PDF Processors
      poppler_utils

      # Databases
      postgresql

  ];

  # Programs
  programs = {
      bat = {
          enable = true;
          config = {
              theme = "GitHub";
          };
      };

      bottom.enable = true;

      command-not-found.enable = true;

      exa = {
          enable = true;
      };

      # later
      firefox = {};

      fzf = {
          enable = true;
          enableFishIntegration = true;
      };

      gh = {
          enable = true;
          gitProtocol = "ssh";
      };

      jq.enable = true;

      nushell.enable = true;
  };
}
