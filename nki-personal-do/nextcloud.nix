{ lib, pkgs, config, ... }:
with lib;
let
  user = "nextcloud";
  host = "cloud.dtth.ch";
  port = 61155;

  secrets = config.sops.secrets;
in
{
  sops.secrets."nextcloud/admin-password" = { owner = user; };
  sops.secrets."nextcloud/minio-secret-key" = { owner = user; key = "minio-secret-key"; };
  # database
  cloud.postgresql.databases = [ user ];
  # traefik
  cloud.traefik.hosts.nextcloud = {
    inherit port host;
  };
  systemd.services.nextcloud.requires = [ "postgresql.service" ];
  services.nextcloud = {
    enable = true;
    hostName = host;
    package = pkgs.nextcloud26;
    enableBrokenCiphersForSSE = false;

    home = "/mnt/data/nextcloud";
    https = true;
    database.createLocally = false;

    extraApps = with pkgs.nextcloud26Packages.apps; {
      inherit calendar contacts deck forms groupfolders news tasks;
      sociallogin = pkgs.fetchNextcloudApp rec {
        url = "https://github.com/zorn-v/nextcloud-social-login/releases/download/v5.4.3/release.tar.gz";
        sha256 = "sha256-ZKwtF9j9WFIk3MZgng9DmN00A73S2Rb4qbehL9adaZo=";
      };
    };

    config = {
      # Database
      dbtype = "pgsql";
      dbname = user;
      dbuser = user;
      dbhost = "/run/postgresql";
      # User
      adminuser = "nki";
      adminpassFile = secrets."nextcloud/admin-password".path;
      # General
      overwriteProtocol = "https";
      defaultPhoneRegion = "VN";

      objectstore.s3 = {
        enable = true;
        bucket = "nextcloud-dtth";
        autocreate = true;
        key = "minio";
        secretFile = config.sops.secrets."nextcloud/minio-secret-key".path;
        hostname = "s3.dtth.ch";
        port = 443;
        useSsl = true;
        usePathStyle = true;
        region = "us-east-1";
      };
    };
  };
  services.nginx.virtualHosts.${host}.listen = [{ inherit port; addr = "127.0.0.1"; }];
}

