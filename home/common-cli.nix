{
  config,
  pkgs,
  lib,
  ...
}:

# Command-line setup shared by every home configuration (Linux and macOS).
# Nothing here may depend on a graphical session, on systemd, or on NixOS.
{
  imports = [
    ./kakoune.nix
    ./fish/fish.nix
    ./modules/programs/my-broot.nix
  ];

  # Temporarily disable the manuals
  manual.html.enable = false;
  # manual.manpage.enable = false;

  # Packages that are not in programs section
  home.packages = with pkgs; [
    # CLI tools
    fd
    sd
    ripgrep
    forgejo-cli
    glab # gitlab CLI
    fx # JSON viewer
    glow # Markdown viewer
    nix-output-monitor # Nice nix output formatting
    tnotify # Desktop notifications from the terminal
    unstable.scala-next
    ## PDF Processors
    poppler-utils
    # TeX
    texlive.schemes.texliveFull
    texlab # for inverse search
    ## htop replacement
    htop-vim
    ## Bitwarden
    rbw
    ## File compression stuff
    ouch

    pkgs.unstable.scala-cli
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
  programs = lib.mkMerge [
    {
      # Let Home Manager install and manage itself.
      home-manager.enable = true;

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

      jq.enable = true;

      nushell.enable = true;
    }

    # Git stuff
    {
      delta = {
        enable = true;
        enableGitIntegration = true;
        options.line-numbers = true;
      };
      git = {
        enable = true;
        signing = {
          format = "ssh";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPPu7NnDh5A51UCj2teRxm3TUdVk3Ed2IAh4HQyJtMgC nki@nkagami.me";
          signByDefault = true;
        };
        settings = {
          user.email = "nki@nkagami.me";
          user.name = "Natsu Kagami";
          init.defaultBranch = "master";
          core.excludesFile = "${pkgs.writeText ".gitignore" ''
            .direnv
            .envrc
            .kakrc
            .atc
          ''}";
          commit.verbose = true;
          safe.directory = "*";
          merge.conflictstyle = "zdiff3";
        };
      };
    }
  ];

  xdg.configFile."forgejo-cli/client_ids".text = ''
    git.dtth.ch 63b49907-9901-40df-bf63-819978ccb82c
  '';
}
