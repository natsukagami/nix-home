{
  lib,
  pkgs,
  ...
}:
let
  user = "satisfactory";
in
{

  users.groups.${user} = { };
  users.users.${user} = {
    isSystemUser = true;
    group = user;
  };

  systemd.services.satisfactory-server = {
    enable = true;
    description = "Satisfactory dedicated server";
    wants = [
      "network-online.target"
      "tailscale.service"
    ];
    after = [
      "syslog.target"
      "network.target"
      "nss-lookup.target"
      "network-online.target"
      "tailscale.service"
    ];

    preStart = ''
      ${lib.getExe pkgs.steamcmd} +force_install_dir /mnt/steam/Satisfactory +login anonymous +app_update 1690800 validate +quit
    '';
    script = "/mnt/steam/Satisfactory/FactoryServer.sh";
    serviceConfig = {
      User = user;
      Group = user;
      Restart = "on-failure";
      RestartSec = 60;
      KillSignal = "SIGINT";
      WorkingDirectory = "/mnt/steam/Satisfactory/";
    };
  };

  networking.firewall.allowedTCPPorts = [
    7777
    8888
  ];
  networking.firewall.allowedUDPPorts = [ 7777 ];
}
