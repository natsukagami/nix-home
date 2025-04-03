{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;
  cfg = config.services.peertube;

  user = "peertube";
  host = "peertube.dtth.ch";
  dataFolder = "/mnt/data/peertube";
  port = 19878;
in
{
  sops.secrets."peertube" = {
    owner = cfg.user;
    restartUnits = [ "peertube.service" ];
  };
  sops.secrets."peertube-env" = {
    owner = cfg.user;
    restartUnits = [ "peertube.service" ];
  };
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

    # Trust proxy
    settings.trust_proxy = [
      "loopback"
    ] ++ config.services.traefik.staticConfigOptions.entrypoints.https.forwardedHeaders.trustedIPs;

    # Federation
    settings.federation = {
      sign_federated_fetches = true;
      videos.federate_unlisted = true;
      videos.cleanup_remote_interactions = true;
    };

    dataDirs = [
      "/var/lib/peertube"
      "/mnt/data/peertube"
    ];
  };

  systemd.services.peertube = {
    requires = [ "arion-authentik.service" ];
    after = [ "arion-authentik.service" ];
    unitConfig.RequiresMountsFor = [ dataFolder ];
  };
  systemd.tmpfiles.settings."10-peertube" = {
    # The service hard-codes a lot of paths here, so it's nicer if we just symlink
    "/var/lib/peertube"."L+" = {
      argument = dataFolder;
    };
    ${dataFolder}."d" = {
      user = user;
      group = user;
      mode = "0700";
    };
  };
}
