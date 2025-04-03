{
  config,
  pkgs,
  lib,
  ...
}:
let
  ipv6-rotator =
    let
      src = pkgs.fetchFromGitHub {
        owner = "iv-org";
        repo = "smart-ipv6-rotator";
        rev = "61c019c2b14304c2a111a6db4c492d10ab2308cf";
        hash = "sha256-a4BQH2D7La51vdPqMQSlZB73twX9Zcjq8mxbT5SdCpo=";
      };
    in
    pkgs.writeShellApplication {
      name = "smart-ipv6-rotator";
      runtimeInputs = [
        (pkgs.python3.withPackages (
          p: with p; [
            pyroute2
            requests
          ]
        ))
      ];
      text = ''
        if [ -z "$IPV6_ROTATOR_RANGE" ]; then
          echo "Range required"
          exit 1
        fi
        python3 ${src}/smart-ipv6-rotator.py "$@" --ipv6range="$IPV6_ROTATOR_RANGE"
      '';
    };
in
{
  sops.secrets."invidious" = {
    mode = "0444";
  };
  sops.secrets."invidious-rotator-env" = {
    mode = "0444";
  };
  cloud.postgresql.databases = [ "invidious" ];
  cloud.traefik.hosts.invidious = {
    host = "invi.dtth.ch";
    port = 61191;
  };
  services.invidious = {
    enable = true;
    domain = "invi.dtth.ch";
    port = 61191;
    extraSettingsFile = config.sops.secrets.invidious.path;
    settings = {
      db.user = "invidious";
      db.dbname = "invidious";

      external_port = 443;
      https_only = true;
      hsts = false;

      registration_enabled = true;
      login_enabled = true;
      admins = [ "nki" ];
      # video_loop = false;
      # autoplay = true;
      # continue = true;
      # continue_autoplay = true;
      # listen = false;
      # quality = "hd720";
      # comments = [ "youtube" ];
      # captions = [ "en" "vi" "de" "fr" ];
    };
  };
  systemd.timers.smart-ipv6-rotator = {
    description = "Rotate ipv6 routes to Google";
    timerConfig = {
      OnCalendar = "*-*-* 00,06,12,18:00:00";
    };
    wantedBy = [
      "invidious.service"
      "timers.target"
    ];
    unitConfig = { };
  };
  systemd.services.smart-ipv6-rotator = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${ipv6-rotator}/bin/smart-ipv6-rotator run";
      EnvironmentFile = [
        config.sops.secrets.invidious-rotator-env.path
      ];
    };
  };
}
