{ config, pkgs, lib, ... }: {
  cloud.postgresql.databases = [ "invidious" ];
  cloud.traefik.hosts.invidious = { host = "invi.dtth.ch"; port = 61191; };
  services.invidious = {
    enable = true;
    domain = "invi.dtth.ch";
    port = 61191;
    settings = {
      db.user = "invidious";
      db.dbname = "invidious";

      https_only = true;
      hsts = false;

      registration_enabled = true;
      login_enabled = true;
      admins = [ "nki" ];
      # video_loop = false;
      # autoplay = true;
      # continue = true;
      # continue_autoplay = true;
      # listen = false;
      # quality = "hd720";
      # comments = [ "youtube" ];
      # captions = [ "en" "vi" "de" "fr" ];
    };
  };
}
