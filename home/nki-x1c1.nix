{ pkgs, config, lib, ... } :

{
  imports = [
      # Common configuration
      ./common.nix
      # Set up X11-specific common configuration
      # ./X11/default.nix
      # ./X11/hidpi.nix # Enable hiDPI
      # We use our own firefox
      # ./firefox.nix
      # osu!
      # ./osu.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "nki";
  home.homeDirectory = "/home/nki";

  # More packages
  home.packages = (with pkgs; [
      # CLI stuff
      python
      zip
      # TeX
      texlive.combined.scheme-full

      # Java & sbt
      openjdk11
      sbt
  ]);

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";
}

