{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) toString;
  inherit (lib)
    types
    mkIf
    mkOption
    mkDefault
    ;
  inherit (lib)
    optional
    optionals
    optionalAttrs
    optionalString
    ;

  inherit (pkgs) sqlite;

  format = pkgs.formats.ini {
    mkKeyValue =
      key: value:
      let
        value' = lib.optionalString (value != null) (
          if builtins.isBool value then if value == true then "true" else "false" else toString value
        );
      in
      "${key} = ${value'}";
  };

  cfg = config.nki.services.writefreely;

  isSqlite = cfg.database.type == "sqlite3";
  isMysql = cfg.database.type == "mysql";
  isMysqlLocal = isMysql && cfg.database.createLocally == true;

  hostProtocol = if cfg.acme.enable then "https" else "http";

  settings = cfg.settings // {
    app = cfg.settings.app or { } // {
      host = cfg.settings.app.host or "${hostProtocol}://${cfg.host}";
    };

    database =
      if cfg.database.type == "sqlite3" then
        {
          type = "sqlite3";
          filename = cfg.settings.database.filename or "writefreely.db";
          database = cfg.database.name;
        }
      else
        {
          type = "mysql";
          username = cfg.database.user;
          password = "#dbpass#";
          database = cfg.database.name;
          host = cfg.database.host;
          port = cfg.database.port;
          tls = cfg.database.tls;
        };

    server = cfg.settings.server or { } // {
      bind = cfg.settings.server.bind or "localhost";
      gopher_port = cfg.settings.server.gopher_port or 0;
      autocert = !cfg.nginx.enable && cfg.acme.enable;
      templates_parent_dir = cfg.settings.server.templates_parent_dir or cfg.package.src;
      static_parent_dir = cfg.settings.server.static_parent_dir or assets;
      pages_parent_dir = cfg.settings.server.pages_parent_dir or cfg.package.src;
      keys_parent_dir = cfg.settings.server.keys_parent_dir or cfg.stateDir;
    };

    "oauth.generic" =
      cfg.settings."oauth.generic" or { }
      // (
        if cfg.oauth.enable then
          {
            client_id = cfg.oauth.clientId;
            client_secret = "#oauth_client_secret#";
            host = cfg.oauth.host;
            display_name = cfg.oauth.displayName;
            callback_proxy = cfg.oauth.callbackProxy;
            callback_proxy_api = cfg.oauth.callbackProxyApi;
            token_endpoint = cfg.oauth.tokenEndpoint;
            inspect_endpoint = cfg.oauth.inspectEndpoint;
            auth_endpoint = cfg.oauth.authEndpoint;
            scope = lib.concatStringsSep " " cfg.oauth.scopes;
            allow_disconnect = cfg.oauth.allowDisconnect;
            map_user_id = cfg.oauth.mapUserId;
            map_username = cfg.oauth.mapUsername;
            map_display_name = cfg.oauth.mapDisplayName;
            map_email = cfg.oauth.mapEmail;
          }
        else
          { }
      );
  };

  configFile = format.generate "config.ini" settings;

  assets = pkgs.stdenvNoCC.mkDerivation {
    pname = "writefreely-assets";

    inherit (cfg.package) version src;

    nativeBuildInputs = with pkgs.nodePackages; [ less ];

    buildPhase = ''
      mkdir -p $out

      cp -r static $out/
    '';

    installPhase = ''
      less_dir=$src/less
      css_dir=$out/static/css

      lessc $less_dir/app.less $css_dir/write.css
      lessc $less_dir/fonts.less $css_dir/fonts.css
      lessc $less_dir/icons.less $css_dir/icons.css
      lessc $less_dir/prose.less $css_dir/prose.css
    '';
  };

  withConfigFile = text: ''
    db_pass=${
      optionalString (cfg.database.passwordFile != null) "$(head -n1 ${cfg.database.passwordFile})"
    }
    oauth_client_secret=${optionalString cfg.oauth.enable "$(head -n1 ${cfg.oauth.clientSecretFile})"}

    cp -f ${configFile} '${cfg.stateDir}/config.ini'
    sed -e "s,#dbpass#,$db_pass,g" -i '${cfg.stateDir}/config.ini'
    sed -e "s,#oauth_client_secret#,$oauth_client_secret,g" -i '${cfg.stateDir}/config.ini'
    chmod 440 '${cfg.stateDir}/config.ini'

    ${text}
  '';

  withMysql =
    text:
    withConfigFile ''
      query () {
        local result=$(${config.services.mysql.package}/bin/mysql \
          --user=${cfg.database.user} \
          --password=$db_pass \
          --database=${cfg.database.name} \
          --silent \
          --raw \
          --skip-column-names \
          --execute "$1" \
        )

        echo $result
      }

      ${text}
    '';

  withSqlite =
    text:
    withConfigFile ''
      query () {
        local result=$(${sqlite}/bin/sqlite3 \
          '${cfg.stateDir}/${settings.database.filename}' \
          "$1" \
        )

        echo $result
      }

      ${text}
    '';
in
{
  options.nki.services.writefreely = {
    enable = lib.mkEnableOption "Writefreely, build a digital writing community";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.writefreely;
      defaultText = lib.literalExpression "pkgs.writefreely";
      description = "Writefreely package to use.";
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/writefreely";
      description = "The state directory where keys and data are stored.";
    };

    user = mkOption {
      type = types.str;
      default = "writefreely";
      description = "User under which Writefreely is ran.";
    };

    group = mkOption {
      type = types.str;
      default = "writefreely";
      description = "Group under which Writefreely is ran.";
    };

    host = mkOption {
      type = types.str;
      default = "";
      description = "The public host name to serve.";
      example = "example.com";
    };

    settings = mkOption {
      default = { };
      description = ''
        Writefreely configuration ({file}`config.ini`). Refer to
        <https://writefreely.org/docs/latest/admin/config>
        for details.
      '';

      type = types.submodule {
        freeformType = format.type;

        options = {
          app = {
            theme = mkOption {
              type = types.str;
              default = "write";
              description = "The theme to apply.";
            };
          };

          server = {
            port = mkOption {
              type = types.port;
              default = if cfg.nginx.enable then 18080 else 80;
              defaultText = "80";
              description = "The port WriteFreely should listen on.";
            };
          };
        };
      };
    };

    database = {
      type = mkOption {
        type = types.enum [
          "sqlite3"
          "mysql"
        ];
        default = "sqlite3";
        description = "The database provider to use.";
      };

      name = mkOption {
        type = types.str;
        default = "writefreely";
        description = "The name of the database to store data in.";
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = if cfg.database.type == "mysql" then "writefreely" else null;
        defaultText = "writefreely";
        description = "The database user to connect as.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "The file to load the database password from.";
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "The database host to connect to.";
      };

      port = mkOption {
        type = types.port;
        default = 3306;
        description = "The port used when connecting to the database host.";
      };

      tls = mkOption {
        type = types.bool;
        default = false;
        description = "Whether or not TLS should be used for the database connection.";
      };

      migrate = mkOption {
        type = types.bool;
        default = true;
        description = "Whether or not to automatically run migrations on startup.";
      };

      createLocally = mkOption {
        type = types.bool;
        default = false;
        description = ''
          When {option}`services.writefreely.database.type` is set to
          `"mysql"`, this option will enable the MySQL service locally.
        '';
      };
    };

    oauth = {
      enable = lib.mkEnableOption "Enable generic OAuth authentication";
      clientId = mkOption {
        type = types.str;
        description = "The client ID associated with WriteFreely in the OAuth provider application.";
      };
      clientSecretFile = mkOption {
        type = types.str;
        description = "The file to load the OAuth client secret from.";
      };
      host = mkOption {
        type = types.str;
        description = "The base url of the OAuth provider application, including the protocol.";
        example = "https://example.com";
      };
      displayName = mkOption {
        type = types.str;
        description = "The human-readable name of the OAuth service that appears on the login button, will appear as `Log in with [display_name]`.";
      };

      callbackProxy = mkOption {
        type = types.str;
        default = "";
        description = "The url of an inbound proxy that sits in front of the default `/oauth/callback/generic` endpoint. Use if you want the OAuth callback to be somewhere other than that generic location. Default is blank.";
        example = "https://example.com/whatever/path";
      };
      callbackProxyApi = mkOption {
        type = types.str;
        default = "";
        description = "The url of an outbound proxy to send your OAuth requests through. Default is blank.";
        example = "https://my-proxy.example.com";
      };

      tokenEndpoint = mkOption {
        type = types.str;
        description = "The API endpoint of the OAuth provider implementation to obtain an access token by presenting an authorization grant or refresh token. This is a fragment of a url, appended to host as described above.";
        example = "/oauth/token";
      };
      inspectEndpoint = mkOption {
        type = types.str;
        description = "The API endpoint of the OAuth provider that returns basic user info given their authentication information. This is a fragment of a url, appended to host as described above.";
        example = "/oauth/userinfo";
      };
      authEndpoint = mkOption {
        type = types.str;
        description = "The API endpoint of the OAuth provider that returns an authorization grant. This is a fragment of a url, appended to host as described above.";
        example = "public";
      };

      scopes = mkOption {
        type = types.listOf types.str;
        default = [ "read_user" ];
        description = "A scope or set of scopes required by some OAuth providers. This will usually be blank in this config file, and is set to `read_user` by default.";
      };
      allowDisconnect = mkOption {
        type = types.bool;
        default = false;
        description = "Whether or not an individual user is allowed to disconnect this OAuth provider from their account.";
      };

      mapUserId = mkOption {
        type = types.str;
        default = "";
        defaultText = "<none>";
        description = "Use this User ID key in the provider's user info, instead of the default key (user_id).";
      };
      mapUsername = mkOption {
        type = types.str;
        default = "";
        defaultText = "<none>";
        description = "Use this Username key in the provider's user info, instead of the default key (username)";
      };
      mapDisplayName = mkOption {
        type = types.str;
        default = "";
        defaultText = "<none>";
        description = "Use this Display Name key in the provider's user info, instead of the default key (*none*)";
      };
      mapEmail = mkOption {
        type = types.str;
        default = "";
        defaultText = "<none>";
        description = "Use this Email key in the provider's user info, instead of the default key (email)";
      };
    };

    admin = {
      name = mkOption {
        type = types.nullOr types.str;
        description = "The name of the first admin user.";
        default = null;
      };

      initialPasswordFile = mkOption {
        type = types.path;
        description = ''
          Path to a file containing the initial password for the admin user.
          If not provided, the default password will be set to `nixos`.
        '';
        default = pkgs.writeText "default-admin-pass" "nixos";
        defaultText = "/nix/store/xxx-default-admin-pass";
      };
    };

    nginx = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether or not to enable and configure nginx as a proxy for WriteFreely.";
      };

      forceSSL = mkOption {
        type = types.bool;
        default = false;
        description = "Whether or not to force the use of SSL.";
      };
    };

    acme = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether or not to automatically fetch and configure SSL certs.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.host != "";
        message = "services.writefreely.host must be set";
      }
      {
        assertion = isMysqlLocal -> cfg.database.passwordFile != null;
        message = "services.writefreely.database.passwordFile must be set if services.writefreely.database.createLocally is set to true";
      }
      {
        assertion = isSqlite -> !cfg.database.createLocally;
        message = "services.writefreely.database.createLocally has no use when services.writefreely.database.type is set to sqlite3";
      }
    ];

    users = {
      users = optionalAttrs (cfg.user == "writefreely") {
        writefreely = {
          group = cfg.group;
          home = cfg.stateDir;
          isSystemUser = true;
        };
      };

      groups = optionalAttrs (cfg.group == "writefreely") { writefreely = { }; };
    };

    systemd.tmpfiles.settings."10-writefreely".${cfg.stateDir}.d = {
      inherit (cfg) user group;
      mode = "0750";
    };

    systemd.services.writefreely = {
      after =
        [ "network.target" ]
        ++ optional isSqlite "writefreely-sqlite-init.service"
        ++ optional isMysql "writefreely-mysql-init.service"
        ++ optional isMysqlLocal "mysql.service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.stateDir;
        Restart = "always";
        RestartSec = 20;
        ExecStart = "${cfg.package}/bin/writefreely -c '${cfg.stateDir}/config.ini' serve";
        AmbientCapabilities = optionalString (settings.server.port < 1024) "cap_net_bind_service";
      };

      preStart = ''
        if ! test -d "${cfg.stateDir}/keys"; then
          mkdir -p ${cfg.stateDir}/keys

          # Key files end up with the wrong permissions by default.
          # We need to correct them so that Writefreely can read them.
          chmod -R 750 "${cfg.stateDir}/keys"

          ${cfg.package}/bin/writefreely -c '${cfg.stateDir}/config.ini' keys generate
        fi
      '';
    };

    systemd.services.writefreely-sqlite-init = mkIf isSqlite {
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.stateDir;
        ReadOnlyPaths = optional (cfg.admin.initialPasswordFile != null) cfg.admin.initialPasswordFile;
      };

      script =
        let
          migrateDatabase = optionalString cfg.database.migrate ''
            ${cfg.package}/bin/writefreely -c '${cfg.stateDir}/config.ini' db migrate
          '';

          createAdmin = optionalString (cfg.admin.name != null) ''
            if [[ $(query "SELECT COUNT(*) FROM users") == 0 ]]; then
              admin_pass=$(head -n1 ${cfg.admin.initialPasswordFile})

              ${cfg.package}/bin/writefreely -c '${cfg.stateDir}/config.ini' --create-admin ${cfg.admin.name}:$admin_pass
            fi
          '';
        in
        withSqlite ''
          if ! test -f '${settings.database.filename}'; then
            ${cfg.package}/bin/writefreely -c '${cfg.stateDir}/config.ini' db init
          fi

          ${migrateDatabase}

          ${createAdmin}
        '';
    };

    systemd.services.writefreely-mysql-init = mkIf isMysql {
      wantedBy = [ "multi-user.target" ];
      after = optional isMysqlLocal "mysql.service";

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.stateDir;
        ReadOnlyPaths =
          optional isMysqlLocal cfg.database.passwordFile
          ++ optional (cfg.admin.initialPasswordFile != null) cfg.admin.initialPasswordFile;
      };

      script =
        let
          updateUser = optionalString isMysqlLocal ''
            # WriteFreely currently *requires* a password for authentication, so we
            # need to update the user in MySQL accordingly. By default MySQL users
            # authenticate with auth_socket or unix_socket.
            # See: https://github.com/writefreely/writefreely/issues/568
            ${config.services.mysql.package}/bin/mysql --skip-column-names --execute "ALTER USER '${cfg.database.user}'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$db_pass'); FLUSH PRIVILEGES;"
          '';

          migrateDatabase = optionalString cfg.database.migrate ''
            ${cfg.package}/bin/writefreely -c '${cfg.stateDir}/config.ini' db migrate
          '';

          createAdmin = optionalString (cfg.admin.name != null) ''
            if [[ $(query 'SELECT COUNT(*) FROM users') == 0 ]]; then
              admin_pass=$(head -n1 ${cfg.admin.initialPasswordFile})
              ${cfg.package}/bin/writefreely -c '${cfg.stateDir}/config.ini' --create-admin ${cfg.admin.name}:$admin_pass
            fi
          '';
        in
        withMysql ''
          ${updateUser}

          if [[ $(query "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${cfg.database.name}'") == 0 ]]; then
            ${cfg.package}/bin/writefreely -c '${cfg.stateDir}/config.ini' db init
          fi

          ${migrateDatabase}

          ${createAdmin}
        '';
    };

    services.mysql = mkIf isMysqlLocal {
      enable = true;
      package = mkDefault pkgs.mariadb;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensurePermissions = {
            "${cfg.database.name}.*" = "ALL PRIVILEGES";
            # WriteFreely requires the use of passwords, so we need permissions
            # to `ALTER` the user to add password support and also to reload
            # permissions so they can be used.
            "*.*" = "CREATE USER, RELOAD";
          };
        }
      ];
    };

    services.nginx = lib.mkIf cfg.nginx.enable {
      enable = true;
      recommendedProxySettings = true;

      virtualHosts."${cfg.host}" = {
        enableACME = cfg.acme.enable;
        forceSSL = cfg.nginx.forceSSL;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString settings.server.port}";
        };
      };
    };
  };
}
