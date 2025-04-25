{
  config,
  lib,
  ...
}:
{

  sops.secrets."ntfy/env" = {
    reloadUnits = [ "ntfy-sh.service" ];
  };

  # ntfy
  cloud.traefik.hosts.ntfy-sh = {
    host = "ntfy.nkagami.me";
    port = 11161;
    noCloudflare = true;
  };
  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = "127.0.0.1:11161";
      cache-file = "/var/lib/ntfy-sh/cache.db";
      auth-file = "/var/lib/ntfy-sh/auth.db";
      auth-default-access = "deny-all";
      behind-proxy = true;
      base-url = "https://ntfy.nkagami.me";
      attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
      enable-login = true;
      enable-reservations = true;
      upstream-base-url = "https://ntfy.sh";
    };
  };
  systemd.services.ntfy-sh = {
    serviceConfig = {
      WorkingDirectory = "%S";
      StateDirectory = "ntfy-sh";
      CacheDirectory = "ntfy-sh";
      EnvironmentFile = [ config.sops.secrets."ntfy/env".path ];
      PreStart = ''
        mkdir -p "$(pwd)/attachments"
      '';
    };
  };
}
