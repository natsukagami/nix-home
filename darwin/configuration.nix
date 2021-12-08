{ config, pkgs, lib, ... }:

{
  imports = [
    ../modules/personal/fonts
    ./brew.nix
  ];
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  nix.package = pkgs.nixUnstable;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  programs.fish.enable = true;

  ## Networking related settings
  networking.hostName = "nki-macbook";

  ## Programs
  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    EDITOR = ""; # don't set it by default

    # Homebrew stuff
    # LLVM!
    # To use the bundled libc++ please add the following LDFLAGS:
    LDFLAGS = lib.concatStringsSep " " [
      "-L/opt/homebrew/opt/llvm/lib"
      "-Wl,-rpath,/opt/homebrew/opt/llvm/lib"
      "-L/opt/homebrew/opt/llvm/lib"
      "$LDFLAGS"
    ];
    CPPFLAGS = "-I/opt/homebrew/opt/llvm/include $CPPFLAGS";
  };

  environment.systemPath = lib.mkBefore [
    # Missing from MacOS
    "/usr/local/bin"
    # LaTeX
    "/usr/local/texlive/2021/bin/universal-darwin"
    # Go
    "/usr/local/go/bin"
    # Ruby
    "/opt/homebrew/opt/ruby@2.7/bin"
    # .NET
    "/usr/local/share/dotnet"
    # LLVM!
    "/opt/homebrew/opt/llvm/bin"
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Font configuration

  users.users.nki = {
    name = "nki";
    home = "/Users/nki";
    shell = "${config.home-manager.users.nki.programs.fish.package}/bin/fish";
  };
}
