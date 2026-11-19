{ config, pkgs, ... }:

# Standalone Home Manager configuration for the Mac mini (aarch64-darwin).
# Command-line tools only: no GUI applications and nothing Linux-specific.
{
  imports = [
    ./common-cli.nix
    # Configuration only, Ghostty is not installed from here
    ./modules/programs/ghostty.nix
  ];

  # Used by the `hm-rebuild` fish function, e.g. `hm-rebuild switch`
  home.sessionVariables = {
    HOME_MANAGER_FLAKE = "${config.home.homeDirectory}/Projects/nix-home#nki@mac-mini";
  };

  # Fonts: on macOS, home-manager puts the fonts of `home.packages` into
  # ~/Library/Fonts/HomeManager (the per-user font folder).
  # Same set as the NixOS hosts, minus their fontconfig settings.
  home.packages = import ../modules/personal/fonts/packages.nix pkgs;

  home.file.".latexmkrc".text = ''
    $pdf_previewer = 'open';
  '';

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "26.05";
}
