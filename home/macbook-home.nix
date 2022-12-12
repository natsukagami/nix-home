{ config, pkgs, lib, ... }:

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
    pkgs.x86.anki-bin
  ];

  # Additional settings for programs
  programs.fish.shellAliases = {
    brew64 = "arch -x86_64 /usr/local/bin/brew";
  };
  nki.programs.kitty.enable = true;
  nki.programs.kitty.package = pkgs.hello; # We install kitty for ourselves
  nki.programs.kitty.background = ./images/chise-bg.png;

  home.sessionPath = [
    # Personal .bin
    "$HOME/.bin"
    "$HOME/.local/bin"

    # Rust
    "$HOME/.cargo/bin"
    # Haskell
    "$HOME/.ghcup/bin"
    "$HOME/.cabal/bin"
    # Go
    "$HOME/go/bin"
    # Node.js
    "$HOME/.local/opt/node/bin"
    # Ruby
    "$HOME/.gem/bin"
    "$HOME/.gem/ruby/2.7.0/bin"
  ];

  home.sessionVariables = {
    VISUAL = "$EDITOR";

    # Other C++ stuff
    LIBRARY_PATH = lib.concatStringsSep ":" [
      "$LIBRARY_PATH"
      "$HOME/.local/share/lib"
    ];
    CPATH = lib.concatStringsSep ":" [
      "$CPATH"
      "$HOME/.local/share/include"
    ];

    # Ruby
    GEM_HOME = "$HOME/.gem";

    # .NET
    DOTNET_CLI_TELEMETRY_OPTOUT = "true";

    # Override home-manager package path to first
    PATH = "/etc/profiles/per-user/${config.home.username}/bin:$PATH";
  };

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
