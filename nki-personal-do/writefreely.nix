{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  host = "blog.dtth.ch";
  port = 18074;

  user = "writefreely-dtth";
in
{
  imports = [ ./writefreely/module.nix ];
  # traefik
  cloud.traefik.hosts.writefreely-dtth = { inherit host port; };

  sops.secrets."writefreely-oauth-secret" = {
    owner = user;
  };

  users.users.${user} = {
    isSystemUser = true;
    home = "${config.fileSystems.data.mountPoint}/writefreely-dtth";
    createHome = true;
    group = user;
  };
  users.groups.${user} = { };

  nki.services.writefreely = {
    inherit host user;
    enable = true;

    group = user;

    stateDir = "${config.fileSystems.data.mountPoint}/writefreely-dtth";
    settings = {
      server.port = port;
      app = {
        host = "https://${host}";

        site_name = "DTTH Blog";
        site_description = "Blogs from members of DTTH";
        editor = "pad";

        landing = "/read";
        local_timeline = true;
        default_visibility = "public";

        open_registration = true;
        disable_password_auth = true;
        max_blogs = 5;
        user_invites = "admin";
        min_username_len = 3;

        federation = true;
        wf_modesty = true;
        public_stats = true;
        monetization = false;
      };

      "oauth.generic" = { };
    };

    oauth = {
      enable = true;
      clientId = "rpoTTr2Wz0h4EgOSCHe0G85O8DCQDMup7JW9U9fV";
      clientSecretFile = config.sops.secrets."writefreely-oauth-secret".path;
      host = "https://auth.dtth.ch";
      displayName = "DTTH";
      tokenEndpoint = "/application/o/token/";
      inspectEndpoint = "/application/o/userinfo/";
      authEndpoint = "/application/o/authorize/";
      scopes = [
        "email"
        "openid"
        "profile"
      ];
      mapUserId = "nickname";
      mapUsername = "preferred_username";
      mapDisplayName = "name";
    };

    database.type = "sqlite3";

    admin.name = "nki";
  };
}
