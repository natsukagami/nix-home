{
  config,
  ...
}:
{
  sops.secrets."forgejo-runner/dtthgit/token" = {
    mode = "0444";
  };
  sops.secrets."forgejo-runner/codeberg/token" = {
    mode = "0444";
  };
  services.forgejo-runner = {
    instances.default = {
      enable = true;
      settings = {
        log.level = "info";
        runner.labels = [
          "nixos-latest:docker://nixos/nix"
          "docker:docker://data.forgejo.org/oci/node:24-bookworm"
        ];
        runner = {
          file = ".runner-dtthgit";
          capacity = 4;
          timeout = "3h";
          shutdown_timeout = "3h";
        };
        cache.enabled = true;
        server.connections.dtthgit = {
          url = "https://git.dtth.ch";
          uuid = "214ef532-1478-4b6f-b84e-3400d03ec5ad";
          token_url = "file:${config.sops.secrets."forgejo-runner/dtthgit/token".path}";
        };
        server.connections.codeberg = {
          url = "https://codeberg.org";
          uuid = "d6a181d2-fbb2-43a7-bed2-27a4f52ac0f7";
          token_url = "file:${config.sops.secrets."forgejo-runner/codeberg/token".path}";
        };
      };
    };
  };
  networking.firewall.trustedInterfaces = [ "podman+" ];
}
