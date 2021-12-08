{ config, pkgs, ... }:

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

  ## Erase editor variables
  environment.variables = {
    EDITOR = ""; # don't set it by default
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Font configuration

  users.users.nki = {
    name = "nki";
    home = "/Users/nki";
  };
}
