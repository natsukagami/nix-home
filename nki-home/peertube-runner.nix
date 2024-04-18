{ config, pkgs, lib, ... }:
let
  user = "peertube-runner-nodejs";
  instance = "systemd-instance";
in
{
  sops.secrets."peertube/dtth-key" = {
    restartUnits = [ "peertube-runner.service" ];
  };
  users.groups.${user} = { };
  users.users.${user} = {
    isSystemUser = true;
    group = user;
  };
  sops.templates."peertube-config.toml".owner = user;
  sops.templates."peertube-config.toml".content = ''
    [jobs]
    concurrency = 2

    [ffmpeg]
    threads = 12
    nice = 20

    [[registeredInstances]]
    url = "https://peertube.dtth.ch"
    runnerToken = "${config.sops.placeholder."peertube/dtth-key"}"
    runnerName = "kagamipc"
  '';

  environment.etc."${user}/${instance}/config.toml".source = config.sops.templates."peertube-config.toml".path;


  systemd.services.peertube-runner = {
    description = "PeerTube runner daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    requires = [ ];

    serviceConfig =
      {
        ExecStart = "${lib.getExe' pkgs.peertube.runner "peertube-runner"} server --id ${instance}";
        User = user;
        RuntimeDirectory = user;
        StateDirectory = user;
        CacheDirectory = user;
        # Hardening
        ProtectSystem = "full";
        PrivateDevices = false;
        NoNewPrivileges = true;
        ProtectHome = true;
        CapabilityBoundingSet = "~CAP_SYS_ADMIN";
      };

    environment = {
      NODE_ENV = "production";
      # Override XDG values to fit env-path
      # https://github.com/sindresorhus/env-paths/blob/main/index.js
      XDG_DATA_HOME = "/run";
      XDG_CONFIG_HOME = "/etc";
      XDG_CACHE_HOME = "/var/cache";
      XDG_STATE_HOME = "/var/lib";
    };

    path = with pkgs; [ nodejs ffmpeg ];
  };
}

