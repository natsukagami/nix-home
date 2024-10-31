{ config, pkgs, ... }: {
  sops.secrets.authentik-oidc-client-secret = { owner = "outline"; };
  sops.secrets."outline/smtp-password" = { owner = "outline"; };
  sops.secrets."outline/s3-secret-key" = { owner = "outline"; };

  services.outline = {
    enable = true;
    package = pkgs.outline.overrideAttrs (attrs: {
      patches = attrs.patches or [ ] ++ [
        ../modules/cloud/outline/dtth-wiki.patch
        ../modules/cloud/outline/r2.patch
      ];
    });
    databaseUrl = "postgres://outline:outline@localhost/outline?sslmode=disable";
    redisUrl = "local";
    publicUrl = "https://wiki.dtth.ch";
    port = 18729;
    storage = {
      accessKey = "6ef730e13f172d2ed6ed77f0b5b9bad9";
      secretKeyFile = config.sops.secrets."outline/s3-secret-key".path;
      region = "auto";
      uploadBucketUrl = "https://60c0807121eb35ef52cdcd4a33735fa6.r2.cloudflarestorage.com";
      uploadBucketName = "dtth-outline";
      uploadMaxSize = 50 * 1024 * 1000;
    };
    maximumImportSize = 50 * 1024 * 1000;

    oidcAuthentication = {
      clientId = "3a0c10e00cdcb4a1194315577fa208a747c1a5f7";
      clientSecretFile = config.sops.secrets.authentik-oidc-client-secret.path;
      authUrl = "https://auth.dtth.ch/application/o/authorize/";
      tokenUrl = "https://auth.dtth.ch/application/o/token/";
      userinfoUrl = "https://auth.dtth.ch/application/o/userinfo/";
      displayName = "DTTH Account";
    };

    smtp = {
      fromEmail = "DTTH Wiki <dtth.wiki@nkagami.me>";
      replyEmail = "";
      host = "mx1.nkagami.me";
      username = "dtth.wiki@nkagami.me";
      passwordFile = config.sops.secrets."outline/smtp-password".path;
      port = 465;
      secure = true;
    };

    forceHttps = false;
  };
  cloud.postgresql.databases = [ "outline" ];
  systemd.services.outline.requires = [ "postgresql.service" ];
  systemd.services.outline.environment = {
    AWS_S3_R2 = "true";
    AWS_S3_R2_PUBLIC_URL = "https://s3.wiki.dtth.ch";
  };
  cloud.traefik.hosts.outline = { host = "wiki.dtth.ch"; port = 18729; };
}
