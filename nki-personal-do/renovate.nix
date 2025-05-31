{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets."renovate/RENOVATE_TOKEN" = {
    reloadUnits = [ ];
  };
  sops.secrets."renovate/GIT_PRIVATE_KEY" = {
    reloadUnits = [ ];
  };
  sops.secrets."renovate/GITHUB_COM_TOKEN" = {
    reloadUnits = [ ];
  };

  services.renovate = {
    enable = true;
    credentials = {
      RENOVATE_TOKEN = config.sops.secrets."renovate/RENOVATE_TOKEN".path;
      RENOVATE_GIT_PRIVATE_KEY = config.sops.secrets."renovate/GIT_PRIVATE_KEY".path;
      RENOVATE_GITHUB_COM_TOKEN = config.sops.secrets."renovate/GITHUB_COM_TOKEN".path;
    };
    settings = {
      platform = "gitea";
      endpoint = "https://git.dtth.ch";

      autodiscover = true;
      binarySource = "global";
      allowedCommands = [
        "^nix-update( --flake)?( --version=skip)? \\w+$"
      ];
    };
    runtimePackages = with pkgs; [
      openssh
      go
      cargo
      nodejs
      gradle
      docker

      nix-update
    ];

    schedule = "*:00..50/10:00";
  };
}
