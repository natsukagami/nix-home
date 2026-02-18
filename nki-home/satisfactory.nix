{
  lib,
  pkgs,
  ...
}:
let
  user = "satisfactory";
  dataDir = "/mnt/steam/Satisfactory";
in
{

  users.groups.${user} = { };
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    home = dataDir;
    createHome = true;
  };

  systemd.services.satisfactory-server = {
    enable = true;
    description = "Satisfactory dedicated server";
    wants = [
      "network-online.target"
      "tailscaled.service"
    ];
    after = [
      "syslog.target"
      "network.target"
      "nss-lookup.target"
      "network-online.target"
      "tailscaled.service"
    ];
    wantedBy = [ "multi-user.target" ];

    preStart = ''
      ${lib.getExe pkgs.steamcmd} +force_install_dir "${dataDir}" +login anonymous +app_update 1690800 validate +quit
    '';
    serviceConfig = {
      User = user;
      Group = user;
      Restart = "on-failure";
      RestartSec = 60;
      KillSignal = "SIGINT";
      WorkingDirectory = "${dataDir}/";
      ExecStart = "${dataDir}/FactoryServer.sh";
    };
  };

  networking.firewall.allowedTCPPorts = [
    7777
    8888
  ];
  networking.firewall.allowedUDPPorts = [ 7777 ];
}
