{
  config,
  pkgs,
  lib,
  ...
}:
let
  tmpDir = "/mnt/data/cache/renovate";
in
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

  systemd.services.renovate.serviceConfig.ReadWritePaths = [ tmpDir ];
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
      cacheDir = lib.mkForce tmpDir;

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
      yarn
      gradle
      docker
      config.nix.package

      nix-update
    ];

    schedule = "*:00..50/10:00";
  };

  # Clean cache every day
  systemd.tmpfiles.settings."10-renovate" = {
    ${tmpDir}."q" = {
      user = "root";
      group = "root";
      mode = "0777";
      age = "1d";
    };
  };
}
