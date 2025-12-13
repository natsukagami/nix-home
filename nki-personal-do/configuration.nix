{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix

    # Set up cloud
    ../modules/cloud/authentik
    ../modules/cloud/firezone
    ../modules/cloud/postgresql
    ../modules/cloud/traefik
    ../modules/cloud/bitwarden
    ../modules/cloud/mail
    ../modules/cloud/conduit
    ../modules/cloud/gotosocial

    # Encrypted DNS
    ../modules/services/edns

    ./headscale.nix
    ./gitea.nix
    ./miniflux.nix
    ./writefreely.nix
    ./synapse.nix
    ./phanpy.nix
    ./invidious.nix
    ./owncast.nix
    ./peertube.nix
    ./outline.nix
    ./vikunja.nix
    ./n8n.nix
    ./ntfy.nix
    ./grist.nix
    ./renovate.nix
  ];

  system.stateVersion = "21.11";

  time.timeZone = "Europe/Berlin";

  common.linux.enable = false; # Don't enable the "common linux" module, this is a special machine.

  # Personal user
  users.users.nki = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" ];
    group = "users";
    uid = 1000;
  };

  boot.tmp.cleanOnBoot = true;
  networking.hostName = "nki-personal";
  networking.firewall.allowPing = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLr1Q+PJuDYJtBAVMSU0U2kZi4V0Z7dE+dpRxa4aEDupSlcPCwSEtcpNME1up7z0yxjcIHHkBYq0RobIaLqwEmntnZzz37jg/iiHwyZsN93jZljId1X0uykcMem4ljiqgmRg3Fs8RKj2+N1ovpIZVDOWINLJJDVJntNvwW/anSCtx27FATVdroHoiyXCwVknG6p3bHU5Nd3idRMn45kZ7Qf1J50XUhtu3ehIWI2/5nYIbi8WDnzY5vcRZEHROyTk2pv/m9rRkCTaGnUdZsv3wfxeeT3223k0mUfRfCsiPtNDGwXn66HcG2cmhrBIeDoZQe4XNkzspaaJ2+SGQfO8Zf natsukagami@gmail.com"
  ];
  users.users.root.shell = pkgs.fish;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    git
    htop-vim
    kakoune

    docker-compose
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.extraOptions = "--data-root /mnt/data/docker";

  services.do-agent.enable = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "daily";
    };
  };

  nki.services.edns.enable = true;
  nki.services.edns.ipv6 = true;

  # Secret management
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # tinc
  services.my-tinc.enable = true;
  services.my-tinc.hostName = "cloud";
  sops.secrets."tinc/rsa-private-key" = { };
  sops.secrets."tinc/ed25519-private-key" = { };
  services.my-tinc.rsaPrivateKey = config.sops.secrets."tinc/rsa-private-key".path;
  services.my-tinc.ed25519PrivateKey = config.sops.secrets."tinc/ed25519-private-key".path;

  sops.secrets."nix-build-farm/private-key" = {
    mode = "0400";
  };
  services.nix-build-farm.hostname = "home";
  services.nix-build-farm.privateKeyFile = config.sops.secrets."nix-build-farm/private-key".path;

  # Set up traefik
  sops.secrets.cloudflare-dns-api-token = {
    owner = "traefik";
  };
  sops.secrets.traefik-dashboard-users = {
    owner = "traefik";
  };
  cloud.traefik.cloudflareKeyFile = config.sops.secrets.cloudflare-dns-api-token.path;
  cloud.traefik.dashboard = {
    enable = true;
    usersFile = config.sops.secrets.traefik-dashboard-users.path;
  };
  cloud.traefik.certsDumper.enable = true;

  # Uptime-Kuma
  services.uptime-kuma = {
    enable = true;
    settings.HOST = "127.0.0.1";
    settings.PORT = "16904";
  };
  cloud.traefik.hosts.uptime-kuma = {
    host = "status.nkagami.me";
    port = 16904;
    noCloudflare = true;
  };
  cloud.traefik.hosts.uptime-kuma-dtth = {
    host = "status.dtth.ch";
    port = 16904;
  };
  cloud.traefik.hosts.uptime-kuma-codefun = {
    host = "status.codefun.vn";
    port = 16904;
  };

  # Bitwarden
  sops.secrets.vaultwarden-env = { };
  cloud.bitwarden.envFile = config.sops.secrets.vaultwarden-env.path;

  # Arion
  virtualisation.arion.backend = "docker";

  # Conduit
  sops.secrets.heisenbridge = {
    owner = "heisenbridge";
  };
  cloud.conduit.enable = true;
  cloud.conduit.instances = {
    "nkagami" = {
      host = "m.nkagami.me";
      port = 6167;
      well-known_port = 6168;
      noCloudflare = true;
    };
  };
  cloud.conduit.heisenbridge = {
    enable = true;
    package = pkgs.heisenbridge.overrideAttrs (old: rec {
      version = "1.14.2";

      src = pkgs.fetchFromGitHub {
        owner = "hifi";
        repo = "heisenbridge";
        rev = "refs/tags/v${version}";
        sha256 = "sha256-qp0LVcmWf5lZ52h0V58S6FoIM8RLOd6Y3FRb85j7KRg=";
      };
    });
    appserviceFile = config.sops.secrets.heisenbridge.path;
    homeserver = "https://m.nkagami.me";
  };

  # Navidrome back to the PC
  cloud.traefik.hosts.navidrome = {
    host = "navidrome.nkagami.me";
    port = 4533;
    localHost = "11.0.0.2";
    noCloudflare = true;
  };

  # Mail
  sops.secrets.mail-users = {
    owner = "maddy";
    reloadUnits = [ "maddy.service" ];
  };
  cloud.mail = {
    enable = true;
    debug = true;
    local_ip = config.secrets.ipAddresses."nki.personal";
    tls.certFile = "${config.cloud.traefik.certsDumper.destination}/${config.cloud.mail.hostname}/certificate.crt";
    tls.keyFile = "${config.cloud.traefik.certsDumper.destination}/${config.cloud.mail.hostname}/privatekey.key";
    usersFile = config.sops.secrets.mail-users.path;
  };

  # Youmubot
  sops.secrets.youmubot-env = { };
  services.youmubot = {
    enable = true;
    package = pkgs.youmubot.override { enableCodeforces = false; };
    envFile = config.sops.secrets.youmubot-env.path;
  };

  # Authentik
  sops.secrets.authentik-env = { };
  cloud.authentik.enable = true;
  cloud.authentik.envFile = config.sops.secrets.authentik-env.path;
  cloud.traefik.hosts.authentik = {
    host = "auth.dtth.ch";
    port = config.cloud.authentik.port;
  };

  # Firezone
  sops.secrets.firezone-env = { };
  cloud.firezone.enable = true;
  cloud.firezone.envFile = config.sops.secrets.firezone-env.path;
  cloud.traefik.hosts.firezone = {
    host = "vpn.dtth.ch";
    port = config.cloud.firezone.httpPort;
    localHost = "127.0.0.1";
    noCloudflare = true;
  };
  cloud.traefik.hosts.firezone-vpn = {
    host = "vpn.dtth.ch";
    port = config.cloud.firezone.wireguardPort;
    entrypoints = [ "wireguard" ];
    protocol = "udp";
  };

  # GoToSocial
  sops.secrets.gts-env = {
    restartUnits = [ "gotosocial.service" ];
  };
  cloud.gotosocial = {
    enable = true;
    envFile = config.sops.secrets.gts-env.path;
  };

  # Grist
  sops.secrets."grist/env" = {
    restartUnits = [ "arion-grist.service" ];
  };
  cloud.grist = {
    enable = true;
    envFile = config.sops.secrets."grist/env".path;
    host = "tables.dtth.ch";
  };

  # Trust my own cert
  security.pki.certificateFiles = [ ../nki-home/cert.pem ];
}
