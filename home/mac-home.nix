{ config, pkgs, ... }:

{
  imports = [ ./common.nix ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "nki";
  home.homeDirectory = "/Users/nki";

  # Additional packages to be used only on this MacBook.
  home.packages = with pkgs; [
    anki-bin
  ];

  # Additional settings for programs
  programs.fish.shellAliases = { };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";
}
