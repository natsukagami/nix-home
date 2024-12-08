{ config, lib, pkgs, ... }:
let
  secrets = config.sops.secrets;
  cfg = config.services.peertube;

  host = "peertube.dtth.ch";
  port = 19878;
in
{
  sops.secrets."peertube" = { owner = cfg.user; restartUnits = [ "peertube.service" ]; };
  sops.secrets."peertube-env" = { owner = cfg.user; restartUnits = [ "peertube.service" ]; };
  # database
  cloud.postgresql.databases = [ "peertube" ];
  # traefik
  cloud.traefik.hosts.peertube = {
    inherit port host;
    noCloudflare = true;
  };

  services.peertube = {
    enable = true;
    enableWebHttps = true;
    listenWeb = 443;
    listenHttp = port;
    localDomain = host;

    secrets.secretsFile = secrets."peertube".path;
    serviceEnvironmentFile = secrets."peertube-env".path;

    # Databases
    redis.createLocally = true;
    database = {
      host = "/run/postgresql";
    };

    # S3
    settings.object_storage = {
      enabled = true;

      region = "auto";

      proxy.proxify_private_files = false;

      web_videos = {
        bucket_name = "dtthtube";
        prefix = "web-videos/";
        base_url = "https://content.peertube.dtth.ch";
      };
      streaming_playlists = {
        bucket_name = "dtthtube";
        prefix = "hls-playlists/";
        base_url = "https://content.peertube.dtth.ch";
      };
    };

    # Storage
    settings.client.videos = {
      resumable_upload.max_chunk_size = "90MB";
    };
    settings.storage = {
      storyboards = "/var/lib/peertube/storage/storyboards/";
      tmp = "/mnt/data/peertube/tmp/";
      tmp_persistent = "/mnt/data/peertube/tmp_persistent/";
      web_videos = "/mnt/data/peertube/web-videos/";
    };

    # Trust proxy
    settings.trust_proxy = [ "loopback" ] ++ config.services.traefik.staticConfigOptions.entrypoints.https.forwardedHeaders.trustedIPs;

    # Federation
    settings.federation = {
      sign_federated_fetches = true;
      videos.federate_unlisted = true;
      videos.cleanup_remote_interactions = true;
    };

    dataDirs = [ "/var/lib/peertube" "/mnt/data/peertube" ];
  };

  systemd.services.peertube = {
    requires = [ "arion-authentik.service" ];
    after = [ "arion-authentik.service" ];
  };
}

