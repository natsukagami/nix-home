{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.cloud.authentik;

  mkImage =
    { imageName, imageDigest, ... }: "${imageName}@${imageDigest}";
  # If we can pullImage we can just do
  # mkImage = pkgs.dockerTools.pullImage;

  images = {
    postgresql = mkImage {
      imageName = "postgres";
      finalImageTag = "12-alpine";
      imageDigest = "sha256:f52ffee699232c84d820c35c28656363f4fda6a3e3e934b83f4e5e1898e2bdfa";
    };
    redis = mkImage {
      imageName = "redis";
      finalImageTag = "alpine";
      imageDigest = "sha256:a5481d685c31d0078b319e39639cb4f5c2c9cf4ebfca1ef888f4327be9bcc5a7";
    };
    authentik = mkImage {
      imageName = "ghcr.io/goauthentik/server";
      finalImageTag = "2023.5.3";
      imageDigest = "sha256:a7ccd464402a9cf9bd36df73dd1f85cd90df6dce2d5d721a7de7a55c6f72962a";
    };
  };
  authentikEnv = pkgs.writeText "authentik.env" ''
    AUTHENTIK_POSTGRESQL__PASSWORD=''${PG_PASS}
  '';
  postgresEnv = pkgs.writeText "postgres.env" ''
    POSTGRES_PASSWORD=''${PG_PASS:?database password required}
  '';
in
{
  options.cloud.authentik = {
    enable = mkEnableOption "Enable authentik OAuth server";
    envFile = mkOption {
      type = types.path;
      description = "Path to an environment file that specifies PG_PASS and AUTHENTIK_SECRET_KEY";
    };
    port = mkOption {
      type = types.int;
      description = "Exposed port";
      default = 9480;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.arion-authentik.serviceConfig.EnvironmentFile = cfg.envFile;
    virtualisation.arion.projects.authentik.settings = {
      services.postgresql.service = {
        image = images.postgresql;
        restart = "unless-stopped";
        healthcheck = {
          test = [ "CMD-SHELL" "pg_isready -d $\${POSTGRES_DB} -U $\${POSTGRES_USER}" ];
          start_period = "20s";
          interval = "30s";
          retries = 5;
          timeout = "5s";
        };
        volumes = [ "database:/var/lib/postgresql/data" ];
        environment = {
          POSTGRES_USER = "authentik";
          POSTGRES_DB = "authentik";
        };
        env_file = [ cfg.envFile "${postgresEnv}" ];
      };
      services.redis.service = {
        image = images.redis;
        command = "--save 60 1 --loglevel warning";
        restart = "unless-stopped";
        healthcheck = {
          test = [ "CMD-SHELL" "redis-cli ping | grep PONG" ];
          start_period = "20s";
          interval = "30s";
          retries = 5;
          timeout = "3s";
        };
        volumes = [ "redis:/data" ];
      };
      services.server.service = {
        image = images.authentik;
        command = "server";
        restart = "unless-stopped";
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/custom-templates:/templates"
        ];
        environment = {
          AUTHENTIK_REDIS__HOST = "redis";
          AUTHENTIK_POSTGRESQL__HOST = "postgresql";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
        };
        env_file = [ cfg.envFile "${authentikEnv}" ];
        ports = [
          "127.0.0.1:${toString cfg.port}:9000"
        ];
      };
      services.worker.service = {
        image = images.authentik;
        command = "worker";
        restart = "unless-stopped";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/custom-templates:/templates"
          "/var/lib/authentik/certs:/certs"
        ];
        environment = {
          AUTHENTIK_REDIS__HOST = "redis";
          AUTHENTIK_POSTGRESQL__HOST = "postgresql";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
        };
        env_file = [ cfg.envFile "${authentikEnv}" ];
      };
      docker-compose.volumes = {
        database.driver = "local";
        redis.driver = "local";
      };
    };
  };
}

