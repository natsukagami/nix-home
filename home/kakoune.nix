{ pkgs, lib, ... }:
let

in
{
  imports = [ ./modules/programs/my-kakoune ];

  home.packages = with pkgs; [
    # ctags for peneira
    universal-ctags
  ];

  # xdg.configFile."kak-tree-sitter/config.toml".source = ./kak-tree-sitter.toml;

  # Enable the kakoune package.
  programs.my-kakoune.enable = true;
  programs.my-kakoune.enable-fish-session = true;
}
