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
        rev = "b9cf1f56c86dc8c8269d1f881c34ff88e43611ff";
        hash = "sha256-iUT9tpScggM+N8aafB+V4/vnEr7UHWp+Ub64QRimA8Q=";
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
  sops.secrets."invidious/env" = {
    mode = "0444";
  };
  sops.secrets."invidious/companion-env" = {
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
    extraSettingsFile = config.sops.secrets."invidious/env".path;
    settings = {
      db.user = "invidious";
      db.dbname = "invidious";

      external_port = 443;
      https_only = true;
      hsts = false;
      domain = "invi.dtth.ch";
      use_pubsub_feeds = true;
      use_innertube_for_captions = true;

      registration_enabled = true;
      login_enabled = true;
      admins = [ "nki" ];

      force_resolve = "ipv6";
      invidious_companion = [ { private_url = "http://localhost:8282/companion"; } ];
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
  systemd.services.invidious = {
    requires = [ "docker-invidious-companion.service" ];
    after = [ "docker-invidious-companion.service" ];
  };

  # Create the network first
  # > docker network create --ipv4=false --ipv6 ip6net
  virtualisation.oci-containers.containers.invidious-companion = {
    autoStart = false;
    image = "quay.io/invidious/invidious-companion:latest";
    ports = [ "8282:8282" ];
    pull = "always";
    volumes = [ "companioncache:/var/tmp/youtubei.js:rw" ];
    environmentFiles = [
      config.sops.secrets."invidious/companion-env".path
    ];
    networks = [ "ip6net" ];
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
