{ config, pkgs, lib, ... }:

let
  texlab = pkgs.rustPlatform.buildRustPackage rec {
    pname = "texlab";
    version = "5.7.0";

    src = pkgs.fetchFromGitHub {
      owner = "latex-lsp";
      repo = "texlab";
      rev = "refs/tags/v${version}";
      sha256 = "sha256-GvORAPbQOdVpz4yY66b3OObewU98V26cZ6nrJ35nlkg=";
    };

    cargoSha256 = "sha256-b7v3ODOjY5BQCzVqlLCNUOaZS95AvIvyjOeas2XfRjM=";

    outputs = [ "out" "man" ];

    nativeBuildInputs = with pkgs; [ installShellFiles help2man ];

    buildInputs = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
      libiconv
      Security
      CoreServices
    ]);

    # When we cross compile we cannot run the output executable to
    # generate the man page
    postInstall = ''
      # TexLab builds man page separately in CI:
      # https://github.com/latex-lsp/texlab/blob/v5.7.0/.github/workflows/publish.yml#L127-L131
      help2man --no-info "$out/bin/texlab" > texlab.1
      installManPage texlab.1
    '';
  };
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
    ## Typst
    typst
    ## Python
    python3

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
    # PATH Overrides
    PATH = "${config.home.homeDirectory}/.bin/overrides:$PATH";
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
