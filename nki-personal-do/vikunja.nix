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
    package =
      builtins.seq
        (lib.assertMsg (pkgs.vikunja.version == "0.24.5") "Vikunja probably doesn't need custom versions anymore")
        (pkgs.vikunja.overrideAttrs
          (attrs: {
            src = pkgs.fetchFromGitHub {
              owner = "go-vikunja";
              repo = "vikunja";
              rev = "e57f04ec23e9ff8aa9877d2ea7d571c2a44790b0";
              hash = "sha256-W6o1h6XBPvT1lH1zO5N7HcodksKill5eqSuaFl2kfuY=";
            };

            passthru = attrs.passthru // {
              overrideModAttrs = attrs: {
                outputHash = "sha256-UWjlivF9ySXCAr84A1trCJ/n9pB98ZhEyG11qz3PL7g=";
              };
            };
          }));

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
    serviceConfig.User = user;
    serviceConfig.LoadCredential = [ "VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHENTIK_CLIENTSECRET_FILE:${secrets."vikunja/provider-clientsecret".path}" ];
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

