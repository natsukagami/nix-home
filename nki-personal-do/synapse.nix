{ pkgs, lib, config, ... }:
let
  port = 61001;
  user = "matrix-synapse";
  host = "m.dtth.ch";
  app_services = [
    config.sops.secrets."matrix-synapse-dtth/appservice-discord".path
  ];
in
{
  sops.secrets."matrix-synapse-dtth/oidc-config".owner = user;
  sops.secrets."matrix-synapse-dtth/appservice-discord".owner = user;
  sops.secrets.matrix-discord-bridge = { mode = "0644"; };

  cloud.postgresql.databases = [ user ];
  cloud.traefik.hosts.matrix-synapse = {
    inherit port;
    filter = "Host(`m.dtth.ch`) && (PathPrefix(`/_matrix`) || PathPrefix(`/_synapse/client`))";
  };
  cloud.traefik.hosts.matrix-synapse-delegation = {
    port = port + 1;
    filter = "Host(`dtth.ch`) && PathPrefix(`/.well-known/matrix`)";
  };

  # Synapse instance for DTTH
  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    dataDir = "${config.fileSystems.data.mountPoint}/matrix-synapse-dtth";
    settings = {
      server_name = "dtth.ch";
      enable_registration = false;
      public_baseurl = "https://${host}/";

      listeners = [{
        inherit port;
        x_forwarded = true;
        tls = false;
        resources = [
          { names = [ "client" "federation" ]; compress = false; }
        ];
      }];
      database = {
        name = "psycopg2";
        args = {
          inherit user;
          database = user;
          host = "/var/run/postgresql";
        };
      };
      dynamic_thumbnails = true;

      url_preview_enabled = true;
      url_preview_ip_range_blacklist = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10"
        "192.0.0.0/24"
        "169.254.0.0/16"
        "192.88.99.0/24"
        "198.18.0.0/15"
        "192.0.2.0/24"
        "198.51.100.0/24"
        "203.0.113.0/24"
        "224.0.0.0/4"
        "::1/128"
        "fe80::/10"
        "fc00::/7"
        "2001:db8::/32"
        "ff00::/8"
        "fec0::/10"
      ];
      app_service_config_files = app_services;
    };
    extraConfigFiles = [
      (config.sops.secrets."matrix-synapse-dtth/oidc-config".path)
    ];
  };

  services.matrix-appservice-discord = {
    enable = true;
    environmentFile = config.sops.secrets.matrix-discord-bridge.path;
    settings.bridge = {
      domain = "dtth.ch";
      homeserverUrl = "https://m.dtth.ch";
    };
  };

  services.nginx.virtualHosts.synapse-dtth-wellknown = {
    listen = [{ addr = "127.0.0.1"; port = port + 1; }];
    # Check https://github.com/spantaleev/matrix-docker-ansible-deploy/blob/master/docs/configuring-well-known.md
    # for the file structure.
    root = pkgs.symlinkJoin
      {
        name = "well-known-files-for-synapse";
        paths = [
          (pkgs.writeTextDir ".well-known/matrix/client" (builtins.toJSON {
            "m.homeserver".base_url = "https://${host}";
          }))
          (pkgs.writeTextDir ".well-known/matrix/server" (builtins.toJSON {
            "m.server" = "${host}:443";
          }))
        ];
      };
    # Enable CORS from anywhere since we want all clients to find us out
    extraConfig = ''
      add_header 'Access-Control-Allow-Origin' "*";
    '';
  };
}

