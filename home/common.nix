{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./common-cli.nix
    ./modules/programs/my-waybar.nix
    ./modules/programs/my-sway
    ./modules/programs/my-niri
    ./modules/programs/my-kitty
    ./modules/programs/ghostty.nix
    ./common-linux.nix
  ];

  # Packages that are not in programs section
  # (cross-platform command-line tools live in ./common-cli.nix)
  home.packages = with pkgs; [
    openssh
    inkscape # for TeX svg
    nmon
    ## Bitwarden
    rbw

    distrobox

    openconnect-epfl
  ];
  home.file.".latexmkrc".text = ''
    $pdf_previewer = '${lib.getExe' pkgs.xdg-utils "xdg-open"}';
  '';

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-qt;
  };
}
