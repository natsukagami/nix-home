{ config, pkgs, lib, ... }:
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

  sops.secrets."writefreely-dtth" = { owner = user; };

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

      "oauth.generic" = {
        client_id = "rpoTTr2Wz0h4EgOSCHe0G85O8DCQDMup7JW9U9fV";
        host = "https://auth.dtth.ch";
        display_name = "DTTH";
        token_endpoint = "/application/o/token/";
        inspect_endpoint = "/application/o/userinfo/";
        auth_endpoint = "/application/o/authorize/";
        scope = "email openid profile";
        map_user_id = "nickname";
        map_username = "preferred_username";
        map_display_name = "name";
        allow_registration = true;
      };
    };

    extraSettingsFile = config.sops.secrets."writefreely-dtth".path;

    database.type = "sqlite3";

    admin.name = "nki";
  };
}

