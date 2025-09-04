{
  pkgs,
  config,
  lib,
  ...
}:
let
  secrets = config.sops.secrets;

  host = "hs.dtth.ch";
  port = 19876;
  webuiPort = 19877;

  configFile =
    assert (pkgs.headscale.version == "0.25.1");
    pkgs.writeText "config.yaml" ''
      database:
        postgres:
          host: /var/run/postgresql
          name: headscale
          password_file: null
          port: null
          user: headscale
        sqlite:
          path: /var/lib/headscale/db.sqlite
          write_ahead_log: true
        type: postgres
      derp:
        auto_update_enabled: true
        paths:
        - /run/secrets/headscale/derp-servers/vnm.yaml
        server:
          private_key_path: /var/lib/headscale/derp_server_private.key
        update_frequency: 24h
        urls:
        - https://controlplane.tailscale.com/derpmap/default
      disable_check_updates: true
      dns:
        base_domain: dtth.ts
        extra_records:
        - name: llm.kagamipc.dtth.ts
          type: A
          value: 100.64.0.1
        magic_dns: true
        nameservers:
          global: []
        search_domains: []
        override_local_dns: false
      ephemeral_node_inactivity_timeout: 30m
      listen_addr: 127.0.0.1:19876
      log:
        format: text
        level: info
      noise:
        private_key_path: /var/lib/headscale/noise_private.key
      oidc:
        allowed_domains: []
        allowed_users: []
        client_id: XgHLi5CC7mbW6xF8wuOHq3xxCPagSUaHt1fFM74M
        client_secret_path: /run/secrets/headscale/client_secret
        extra_params: {}
        issuer: https://auth.dtth.ch/application/o/headscale/
        only_start_if_oidc_is_available: true
        scope:
        - openid
        - profile
        - email
        # strip_email_domain: true
      policy:
        mode: file
        path: null
      prefixes:
        allocation: sequential
        v4: 100.64.0.0/10
        v6: fd7a:115c:a1e0::/48
      server_url: https://hs.dtth.ch
      tls_cert_path: null
      tls_key_path: null
      tls_letsencrypt_cache_dir: /var/lib/headscale/.cache
      tls_letsencrypt_challenge_type: HTTP-01
      tls_letsencrypt_hostname: ""
      tls_letsencrypt_listen: :http
      unix_socket: /run/headscale/headscale.sock
    '';
in
{
  config = {
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

      package = pkgs.unstable.headscale;

      settings = {
        server_url = "https://hs.dtth.ch";

        database.type = "postgres";
        database.postgres = {
          host = "/var/run/postgresql"; # find out yourself
          user = "headscale";
          name = "headscale";
        };

        dns = {
          base_domain = "dtth.ts";
          extra_records = [
            {
              name = "llm.kagamipc.dtth.ts";
              type = "A";
              value = "100.64.0.1";
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
          # strip_email_domain = true;
        };
      };
    };

    systemd.services.headscale.script =
      let
        cfg = config.services.headscale;
      in
      lib.mkForce ''
        ${lib.optionalString (cfg.settings.database.postgres.password_file != null) ''
          export HEADSCALE_DATABASE_POSTGRES_PASS="$(head -n1 ${lib.escapeShellArg cfg.settings.database.postgres.password_file})"
        ''}

        exec ${lib.getExe cfg.package} serve --config ${configFile}
      '';

    environment.etc."headscale/config.yaml".mode = "0644";
  };
}
