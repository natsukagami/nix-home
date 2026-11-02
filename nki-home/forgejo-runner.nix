{
  config,
  ...
}:
{
  sops.secrets."forgejo-runner/dtthgit/token" = { };
  sops.secrets."forgejo-runner/codeberg/token" = { };
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
          uuid = "af3acb59-cc30-4cd0-8055-ae04318f1372";
          token_url = config.sops.secrets."forgejo-runner/dtthgit/token".path;
        };
        server.connections.codeberg = {
          url = "https://codeberg.org";
          uuid = "9690ce25-cbc5-4bec-877b-576cace5193f";
          token_url = config.sops.secrets."forgejo-runner/codeberg/token".path;
        };
      };
    };
  };
  networking.firewall.trustedInterfaces = [ "podman+" ];
}
