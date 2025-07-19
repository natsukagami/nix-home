{
  pkgs,
  config,
  lib,
  ...
}:
let
  wg = "wgdeluge";
  webui-port = "58846";
in
{
  services.deluge = {
    enable = true;
    web.enable = true;
  };

  sops.secrets."wg-deluge.conf" = {
    owner = "root";
    mode = "0400";
    reloadUnits = [ "${wg}.service" ];
  };
  # setting up wireguard interface within network namespace
  systemd.services.${wg} =
    let
      ip = lib.getExe' pkgs.iproute2 "ip";
      wireguard = lib.getExe pkgs.wireguard-tools;
    in
    {
      description = "WireGuard network interface for Deluge";
      bindsTo = [ "netns@${wg}.service" ];
      requires = [
        "network-online.target"
        "dnscrypt-proxy2.service"
      ];
      after = [
        "network-online.target"
        "netns@${wg}.service"
        "dnscrypt-proxy2.service"
      ];
      serviceConfig =
        let
          wg-down = pkgs.writers.writeBash "wg-down" ''
            ${ip} -n ${wg} route del default dev ${wg}
            # ${ip} -n ${wg} -6 route del default dev ${wg}
            ${ip} -n ${wg} link del ${wg}
            ${ip} link del ${wg}
          '';
        in
        {
          Type = "oneshot";
          Restart = "on-failure";
          RemainAfterExit = true;
          ExecStart = pkgs.writers.writeBash "wg-up" ''
            set -e
            ${wg-down} || true
            ${ip} link add ${wg} type wireguard
            ${ip} link set ${wg} netns ${wg}
            ${ip} -n ${wg} address add "100.123.50.189/32" dev ${wg}
            ${ip} netns exec ${wg} \
              ${wireguard} setconf ${wg} ${config.sops.secrets."wg-deluge.conf".path}
            ${ip} -n ${wg} link set ${wg} up
            # need to set lo up as network namespace is started with lo down
            ${ip} -n ${wg} link set lo up
            ${ip} -n ${wg} route add default dev ${wg}
            # ${ip} -n ${wg} -6 route add default dev ${wg}
          '';
          ExecStop = wg-down;
        };
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
    };

  # binding deluged to network namespace
  systemd.services.deluged.bindsTo = [ "netns@${wg}.service" ];
  systemd.services.deluged.requires = [
    "network-online.target"
    "proxy-to-deluged.service"
    "${wg}.service"
  ];
  systemd.services.deluged.after = [
    "${wg}.service"
  ];
  systemd.services.deluged.serviceConfig.NetworkNamespacePath = [ "/var/run/netns/${wg}" ];

  # allowing delugeweb to access deluged in network namespace, a socket is necesarry
  systemd.sockets."proxy-to-deluged" = {
    enable = true;
    description = "Socket for Proxy to Deluge Daemon";
    listenStreams = [ "${webui-port}" ];
    wantedBy = [ "sockets.target" ];
  };

  # creating proxy service on socket, which forwards the same port from the root namespace to the isolated namespace
  systemd.services."proxy-to-deluged" = {
    enable = true;
    description = "Proxy to Deluge Daemon in Network Namespace";
    requires = [
      "deluged.service"
      "proxy-to-deluged.socket"
    ];
    after = [
      "deluged.service"
      "proxy-to-deluged.socket"
    ];
    unitConfig = {
      JoinsNamespaceOf = "deluged.service";
    };
    serviceConfig = {
      User = "deluge";
      Group = "deluge";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:${webui-port}";
      PrivateNetwork = "yes";
    };
  };
}
