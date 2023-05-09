{ pkgs, config, lib, ... }:
let
  secrets = config.sops.secrets;

  host = "hs.dtth.ch";
  port = 19876;
  webuiPort = 19877;
in
rec {
  sops.secrets."headscale/client_secret" = { owner = "headscale"; };
  sops.secrets."headscale/webui-env" = { };
  sops.secrets."headscale/derp-servers/vnm" = { owner = "headscale"; name = "headscale/derp-servers/vnm.yaml"; };
  # database
  cloud.postgresql.databases = [ "headscale" ];
  # traefik
  cloud.traefik.hosts.headscale = {
    inherit port host;
    filter = "Host(`hs.dtth.ch`) && !PathPrefix(`/admin`)";
  };
  cloud.traefik.hosts.headscale_webui = {
    inherit host;
    port = webuiPort;
    filter = "Host(`hs.dtth.ch`) && PathPrefix(`/admin`)";
  };

  services.headscale = {
    enable = true;
    package = pkgs.unstable.headscale;
    inherit port;

    settings = {
      server_url = "https://hs.dtth.ch";

      db_type = "postgres";
      db_host = "/var/run/postgresql"; # find out yourself
      db_user = "headscale";
      db_name = "headscale";

      dns_config = {
        base_domain = host;
      };

      noise = {
        private_key_path = "/var/lib/headscale/noise_private.key";
      };

      ip_prefixes = [
        "fd7a:115c:a1e0::/48"
        "100.64.0.0/10"
      ];

      derp.paths = [
        secrets."headscale/derp-servers/vnm".path
      ];

      oidc = {
        only_start_if_oidc_is_available = true;
        client_id = "XgHLi5CC7mbW6xF8wuOHq3xxCPagSUaHt1fFM74M";
        client_secret_path = secrets."headscale/client_secret".path;
        issuer = "https://auth.dtth.ch/application/o/headscale/";
        strip_email_domain = true;
      };
    };
  };

  environment.etc."headscale/config.yaml".mode = "0644";
  virtualisation.arion.projects.headscale-webui.settings = {
    services.webui.service = {
      image = "ghcr.io/ifargle/headscale-webui@sha256:b4f02337281853648b071301af4329b4e4fc9189d77ced2eb2fbb78204321cab";
      restart = "unless-stopped";

      environment = {
        TZ = "Europe/Zurich";
        COLOR = "blue-gray";
        HS_SERVER = "https://hs.dtth.ch";
        SCRIPT_NAME = "/admin";
      };
      env_file = [ secrets."headscale/webui-env".path ];
      ports = [ "${toString webuiPort}:5000" ];
      volumes = [
        "/var/lib/headscale/webui:/data"
        "/etc/headscale:/etc/headscale:ro"
      ];
    };
  };
}
