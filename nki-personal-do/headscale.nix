{
  config,
  ...
}:
let
  secrets = config.sops.secrets;

  host = "hs.dtth.ch";
  port = 19876;
  webuiPort = 19877;
in
{
  sops.secrets."headscale/client_secret" = {
    owner = "headscale";
  };
  sops.secrets."headscale/webui-env" = { };
  sops.secrets."headscale/derp-servers/vnm" = {
    owner = "headscale";
    name = "headscale/derp-servers/vnm.yaml";
  };
  # database
  cloud.postgresql.databases = [ "headscale" ];
  # traefik
  cloud.traefik.hosts.headscale = {
    inherit port host;
    filter = "Host(`hs.dtth.ch`) && !PathPrefix(`/admin`)";
    noCloudflare = true;
  };
  # cloud.traefik.config.http.middlewares.hs-sslheader.headers.customrequestheaders.X-Forwarded-Proto = "https";
  # cloud.traefik.config.http.routers.headscale-router.middlewares = [ "hs-sslheader" ];
  cloud.traefik.hosts.headscale_webui = {
    inherit host;
    port = webuiPort;
    filter = "Host(`hs.dtth.ch`) && PathPrefix(`/admin`)";
    noCloudflare = true;
  };

  systemd.services.headscale.requires = [
    "postgresql.service"
    "arion-authentik.service"
  ];
  systemd.services.headscale.after = [
    "postgresql.service"
    "arion-authentik.service"
  ];
  services.headscale = {
    enable = true;
    inherit port;

    settings = {
      server_url = "https://hs.dtth.ch";

      database.type = "postgres";
      database.postgres = {
        host = "/var/run/postgresql"; # find out yourself
        user = "headscale";
        name = "headscale";
      };

      dns = {
        nameservers.global = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        base_domain = "dtth.ts";
        extra_records = [
          {
            name = "llm.kagamipc.dtth.ts";
            type = "A";
            value = "100.64.0.4";
          }
        ];
      };

      noise = {
        private_key_path = "/var/lib/headscale/noise_private.key";
      };

      prefixes = {
        v6 = "fd7a:115c:a1e0::/48";
        v4 = "100.64.0.0/10";
      };

      derp.paths = [
        secrets."headscale/derp-servers/vnm".path
      ];

      oidc = {
        only_start_if_oidc_is_available = true;
        client_id = "XgHLi5CC7mbW6xF8wuOHq3xxCPagSUaHt1fFM74M";
        client_secret_path = secrets."headscale/client_secret".path;
        issuer = "https://auth.dtth.ch/application/o/headscale/";
      };
    };
  };

  environment.etc."headscale/config.yaml".mode = "0644";
}
