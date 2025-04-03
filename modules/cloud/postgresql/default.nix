{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.cloud.postgresql;

  # From a database name, create an "ensureUser"
  # entry with the same name and assign all permissions
  # to that database.
  userFromDatabase = databaseName: {
    name = databaseName;
    ensureDBOwnership = true;
  };
in
{
  options.cloud.postgresql.databases = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = ''
      The list of databases to be created.
      An user with the same name
      and full access to the database will be created.
    '';
  };

  # PostgreSQL settings.
  config.services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;

    ensureDatabases = cfg.databases;

    ensureUsers = (map userFromDatabase cfg.databases);

    dataDir = "/mnt/data/postgresql/${config.services.postgresql.package.psqlSchema}";
  };

  config.systemd.services.postgresql.serviceConfig = {
    StateDirectory = "postgresql postgresql ${config.services.postgresql.dataDir}";
    StateDirectoryMode = "0750";
  };

  # Backup settings
  config.services.postgresqlBackup = {
    enable = true;
  };

  # Upgrade
  config.environment.systemPackages = [
    (
      let
        # XXX specify the postgresql package you'd like to upgrade to.
        # Do not forget to list the extensions you need.
        newPostgres = pkgs.postgresql_15.withPackages (pp: [
          # pp.plv8
        ]);
      in
      pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"

        export NEWBIN="${newPostgres}/bin"

        export OLDDATA="${config.services.postgresql.dataDir}"
        export OLDBIN="${config.services.postgresql.package}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

        sudo -u postgres $NEWBIN/pg_upgrade \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir $OLDBIN --new-bindir $NEWBIN \
          "$@"
      ''
    )
  ];
}
