{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.cloud.grist;

  mkImage = { imageName, imageDigest, ... }: "${imageName}@${imageDigest}";
  # If we can pullImage we can just do
  # mkImage = pkgs.dockerTools.pullImage;

  images = {
    # https://hub.docker.com/r/gristlabs/grist-oss/tags
    grist = mkImage {
      imageName = "docker.io/gristlabs/grist-oss";
      finalImageTag = "1.7.7";
      imageDigest = "sha256:06ba5357a1980802308bc945a47db4fab0c3e1b2d93e0bd0594afab309f2d9e2";
    };
    # https://hub.docker.com/r/valkey/valkey/tags
    valkey = mkImage {
      imageName = "docker.io/valkey/valkey";
      finalImageTag = "8.0.2-alpine";
      imageDigest = "sha256:0fae58181c223280867e8b6d9d5fa29fca507770aeb6819f36d059cab73fa2fd";
    };
  };
  defaultEnv = {
    GRIST_HIDE_UI_ELEMENTS = lib.concatStringsSep "," [
      "helpCenter"
      "billing"
      "multiAccounts"
      "supportGrist"
    ];
    GRIST_PAGE_TITLE_SUFFIX = " - DTTH Grist";
    GRIST_FORCE_LOGIN = "true";
    GRIST_WIDGET_LIST_URL = "https://github.com/gristlabs/grist-widget/releases/download/latest/manifest.json";
    GRIST_EXTERNAL_ATTACHMENTS_MODE = "snapshots";

    GRIST_SANDBOX_FLAVOR = "gvisor";
    PYTHON_VERSION = "3";
    PYTHON_VERSION_ON_CREATION = "3";
  };
in
{
  options.cloud.grist = {
    enable = mkEnableOption "Grist database server";
    envFile = mkOption {
      type = types.path;
      description = "Path to an environment file that specifies GRIST_SESSION_SECRET and others";
    };
    host = mkOption {
      type = types.str;
      description = "Exposed hostname";
    };
    port = mkOption {
      type = types.int;
      description = "Exposed port";
      default = 9674;
    };

    settings = {
      allowedWebhookDomains = mkOption {
        type = types.listOf types.str;
        description = "List of domains to be allowed in webhooks";
        default = [
          "dtth.ch"
          "nkagami.me"
          "discord.com"
        ];
      };
      defaultEmail = mkOption {
        type = types.str;
        description = "Default email address for admin user";
        default = "nki@nkagami.me";
      };
    };
  };

  config = mkIf cfg.enable {
    cloud.traefik.hosts.grist = {
      inherit (cfg) port host;
    };
    systemd.services.arion-grist = {
      serviceConfig.Type = "notify";
      serviceConfig.NotifyAccess = "all";
      serviceConfig.TimeoutSec = 300;
      script = lib.mkBefore ''
        ${lib.getExe pkgs.wait4x} http http://127.0.0.1:${toString cfg.port} -t 0 -q -- systemd-notify --ready &
      '';
    };
    virtualisation.arion.projects.grist.settings = {
      services.grist-server.service = {
        image = images.grist;
        restart = "unless-stopped";
        volumes = [ "grist:/persist" ];
        environment = defaultEnv // {
          APP_HOME_URL = "https://${cfg.host}";
          ALLOWED_WEBHOOK_DOMAINS = lib.concatStringsSep "," cfg.settings.allowedWebhookDomains;
          GRIST_DEFAULT_EMAIL = cfg.settings.defaultEmail;
          REDIS_URL = "redis://valkey/1";
        };
        env_file = [ cfg.envFile ];
        ports = [
          "127.0.0.1:${toString cfg.port}:8484"
        ];
      };
      services.valkey.service = {
        image = images.valkey;
        command = "--save 60 1 --loglevel warning";
        restart = "unless-stopped";
        healthcheck = {
          test = [
            "CMD-SHELL"
            "valkey-cli ping | grep PONG"
          ];
          start_period = "20s";
          interval = "30s";
          retries = 5;
          timeout = "3s";
        };
        volumes = [ "valkey:/data" ];
      };
      docker-compose.volumes = {
        grist.driver = "local";
        valkey.driver = "local";
      };
    };
  };
}
