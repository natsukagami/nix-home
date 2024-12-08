{ pkgs, lib, config, ... }:
let
  secrets = config.sops.secrets;

  host = "kanban.dtth.ch";
  user = "vikunja";
  port = 12785;

  storageMount = "/mnt/data/vikunja";
in
{
  sops.secrets."vikunja/env" = { restartUnits = [ "vikunja.service" ]; };
  sops.secrets."vikunja/provider-clientsecret" = { restartUnits = [ "vikunja.service" ]; };
  cloud.postgresql.databases = [ user ];
  cloud.traefik.hosts.vikunja = {
    inherit port host;
  };

  # users
  users.users."${user}" = {
    group = "${user}";
    isSystemUser = true;
  };
  users.groups."${user}" = { };


  services.vikunja = {
    inherit port;
    enable = true;

    frontendScheme = "https";
    frontendHostname = host;

    environmentFiles = [ secrets."vikunja/env".path ];

    database = {
      type = "postgres";
      host = "/var/run/postgresql";
      user = user;
      database = user;
    };

    settings = {
      service = {
        publicurl = "https://${host}";
        enableregistration = false;
        enablepublicteams = true;
      };
      mailer = {
        enabled = true;
        host = "mx1.nkagami.me";
        port = 465;
        forcessl = true;
      };
      files.basepath = lib.mkForce storageMount;
      migration = {
        todoist.enable = true;
        trello.enable = true;
      };
      backgrounds.providers.unsplash.enabled = true;
      auth = {
        local.enabled = false;
        openid = {
          enabled = true;
          providers.authentik = {
            name = "DTTH Discord Account";
            authurl = "https://auth.dtth.ch/application/o/vikunja/";
            logouturl = "https://auth.dtth.ch/application/o/vikunja/end-session/";
            clientid = "GvCIBtdE2ZRbAo5BJzw4FbZjer7umJlaROT1Pvlp";
            scope = "openid profile email vikunja_scope";
          };
        };
      };
      defaultsettings = {
        avatar_provider = "gravatar";
        week_start = 1;
        language = "VN";
        timezone = "Asia/Ho_Chi_Minh";
      };
    };
  };

  systemd.services.vikunja = {
    serviceConfig.LoadCredential = [ "VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHENTIK_CLIENTSECRET_FILE:${secrets."vikunja/provider-clientsecret".path}" ];
    serviceConfig.User = user;
    serviceConfig.DynamicUser = lib.mkForce false;
    serviceConfig.ReadWritePaths = [ storageMount ];
    environment.VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHENTIK_CLIENTSECRET_FILE = "%d/VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHENTIK_CLIENTSECRET_FILE";
    unitConfig = {
      RequiresMountsFor = [ storageMount ];
    };
  };
  systemd.tmpfiles.settings."10-vikunja".${storageMount}.d = {
    user = user;
    group = user;
    mode = "0700";
  };
}

