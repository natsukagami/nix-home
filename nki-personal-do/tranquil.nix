{ config, ... }:
let
  hostname = "pds.dtth.ch";
  port = 28186;
  secrets = config.sops.secrets;

in
{
  # traefik
  cloud.traefik.hosts.tranquil-pds = {
    host = hostname;
    port = port;
  };

  sops.secrets."tranquil/env" = { };
  sops.secrets."tranquil/secrets" = { };
  services.tranquil-pds = {
    enable = true;
    database.createLocally = true;

    environmentFiles = [
      secrets."tranquil/env".path
      secrets."tranquil/secrets".path
    ];

    settings = {
      server = {
        inherit hostname port;
        age_assurance_override = true;
        invite_code_required = true;
      };
    };
  };
}
