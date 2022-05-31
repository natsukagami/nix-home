{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.cloud.postgresql;

  # From a database name, create an "ensureUser"
  # entry with the same name and assign all permissions
  # to that database.
  userFromDatabase = databaseName: {
    name = databaseName;
    ensurePermissions = {
      "DATABASE ${databaseName}" = "ALL PRIVILEGES";
    };
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
    package = pkgs.postgresql_13;

    ensureDatabases = cfg.databases;

    ensureUsers = map userFromDatabase cfg.databases;
  };

  # Backup settings
  config.services.postgresqlBackup = {
    enable = true;
  };
}
