let
  # Default shell
  defaultShell =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    with lib;
    {
      environment.shells = with pkgs; [
        bash
        fish
      ];
      users.users = mkMerge [
        { nki.shell = pkgs.bash; }
        # (mkIf (builtins.hasAttr "natsukagami" config.users.users) { natsukagami.shell = pkgs.fish; })
      ];
    };
in
# Common stuff
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
{
  imports = [
    # defaultShell
    ./modules/services/nix-cache
    ./modules/services/nix-build-farm
  ];

  ## Packages
  # Nix options
  # Always have flakes enabled!
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
