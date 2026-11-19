{ ... }:

# Standalone Home Manager configuration for the Mac mini (aarch64-darwin).
# Command-line tools only: no GUI applications and nothing Linux-specific.
{
  imports = [
    ./common-cli.nix
  ];

  home.username = "nki";
  home.homeDirectory = "/Users/nki";

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
