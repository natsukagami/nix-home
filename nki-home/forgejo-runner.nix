{
  config,
  pkgs,
  lib,
  ...
}:
{
  sops.secrets."forgejo-runner/token" = { };
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.dtthgit = {
      enable = true;
      name = "kagamipc-runner";
      tokenFile = config.sops.secrets."forgejo-runner/token".path;
      url = "https://git.dtth.ch";
      labels = [
        "nixos-latest:docker://nixos/nix"
        "docker:docker://data.forgejo.org/oci/node:22-bookworm"
      ];
      settings = {
        log.level = "info";
        runner = {
          file = ".runner";
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
