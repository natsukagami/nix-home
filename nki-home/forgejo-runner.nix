{
  config,
  pkgs,
  lib,
  ...
}:
{
  sops.secrets."forgejo-runner/dtthgit/token" = { };
  sops.secrets."forgejo-runner/codeberg/token" = { };
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.dtthgit = {
      enable = true;
      name = "kagamipc-runner";
      tokenFile = config.sops.secrets."forgejo-runner/dtthgit/token".path;
      url = "https://git.dtth.ch";
      labels = [
        "nixos-latest:docker://nixos/nix"
        "docker:docker://data.forgejo.org/oci/node:24-bookworm"
      ];
      settings = {
        log.level = "info";
        runner = {
          file = ".runner-dtthgit";
          capacity = 4;
          timeout = "3h";
          shutdown_timeout = "3h";
        };
        cache.enabled = true;
      };
    };
    instances.codeberg = {
      enable = true;
      name = "nki-kagamipc-runner";
      tokenFile = config.sops.secrets."forgejo-runner/codeberg/token".path;
      url = "https://codeberg.org";
      labels = [
        "nixos-latest:docker://nixos/nix"
        "docker:docker://data.forgejo.org/oci/node:24-bookworm"
      ];
      settings = {
        log.level = "info";
        runner = {
          file = ".runner-codeberg";
          capacity = 4;
          timeout = "3h";
          shutdown_timeout = "3h";
        };
        cache.enabled = true;
      };
    };
  };
  networking.firewall.trustedInterfaces = [ "podman+" ];
}
