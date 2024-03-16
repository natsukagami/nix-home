{ pkgs, config, lib, ... }: {
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

    ./headscale.nix
    ./gitea.nix
    ./miniflux.nix
    ./writefreely.nix
    ./synapse.nix
    ./phanpy.nix
    ./invidious.nix
    ./owncast.nix
    ./peertube.nix
  ];

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

  services.do-agent.enable = true;

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    flake = "github:natsukagami/nix-home#nki-personal-do";
  };

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

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

  # Set up traefik
  sops.secrets.cloudflare-dns-api-token = { owner = "traefik"; };
  sops.secrets.traefik-dashboard-users = { owner = "traefik"; };
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
  cloud.traefik.hosts.uptime-kuma = { host = "status.nkagami.me"; port = 16904; noCloudflare = true; };
  cloud.traefik.hosts.uptime-kuma-dtth = { host = "status.dtth.ch"; port = 16904; };
  cloud.traefik.hosts.uptime-kuma-codefun = { host = "status.codefun.vn"; port = 16904; };

  # Bitwarden
  sops.secrets.vaultwarden-env = { };
  cloud.bitwarden.envFile = config.sops.secrets.vaultwarden-env.path;

  # Arion
  virtualisation.arion.backend = "docker";

  # Conduit
  sops.secrets.heisenbridge = { owner = "heisenbridge"; };
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
  sops.secrets.mail-users = { owner = "maddy"; };
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
  cloud.traefik.hosts.authentik = { host = "auth.dtth.ch"; port = config.cloud.authentik.port; };

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


  # Outline
  sops.secrets.minio-secret-key = { owner = "root"; mode = "0444"; };
  sops.secrets.authentik-oidc-client-secret = { owner = "outline"; };
  sops.secrets."outline/smtp-password" = { owner = "outline"; };
  services.outline = {
    enable = true;
    package = pkgs.outline.overrideAttrs (attrs: {
      patches = if builtins.hasAttr "patches" attrs then attrs.patches else [ ] ++ [ ../modules/cloud/outline/dtth-wiki.patch ];
    });
    databaseUrl = "postgres://outline:outline@localhost/outline?sslmode=disable";
    redisUrl = "local";
    publicUrl = "https://wiki.dtth.ch";
    port = 18729;
    storage = {
      accessKey = "minio";
      secretKeyFile = config.sops.secrets.minio-secret-key.path;
      region = config.services.minio.region;
      uploadBucketUrl = "https://s3.dtth.ch";
      uploadBucketName = "dtth-outline";
      uploadMaxSize = 50 * 1024 * 1000;
    };
    maximumImportSize = 50 * 1024 * 1000;

    oidcAuthentication = {
      clientId = "3a0c10e00cdcb4a1194315577fa208a747c1a5f7";
      clientSecretFile = config.sops.secrets.authentik-oidc-client-secret.path;
      authUrl = "https://auth.dtth.ch/application/o/authorize/";
      tokenUrl = "https://auth.dtth.ch/application/o/token/";
      userinfoUrl = "https://auth.dtth.ch/application/o/userinfo/";
      displayName = "DTTH Account";
    };

    smtp = {
      fromEmail = "DTTH Wiki <dtth.wiki@nkagami.me>";
      replyEmail = "";
      host = "mx1.nkagami.me";
      username = "dtth.wiki@nkagami.me";
      passwordFile = config.sops.secrets."outline/smtp-password".path;
      port = 465;
      secure = true;
    };

    forceHttps = false;
  };
  cloud.postgresql.databases = [ "outline" ];
  systemd.services.outline.requires = [ "postgresql.service" ];
  cloud.traefik.hosts.outline = { host = "wiki.dtth.ch"; port = 18729; };

  # GoToSocial
  sops.secrets.gts-env = { };
  cloud.gotosocial = {
    enable = true;
    envFile = config.sops.secrets.gts-env.path;
  };

  # Minio
  sops.secrets.minio-credentials = { };
  services.minio = {
    enable = true;
    listenAddress = ":61929";
    consoleAddress = ":62929";
    rootCredentialsFile = config.sops.secrets.minio-credentials.path;
    dataDir = lib.mkForce [ "/mnt/data/minio" ];
  };
  cloud.traefik.hosts.minio = { host = "s3.dtth.ch"; port = 61929; };
  system.stateVersion = "21.11";

  # ntfy
  cloud.traefik.hosts.ntfy-sh = { host = "ntfy.nkagami.me"; port = 11161; noCloudflare = true; };
  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = "127.0.0.1:11161";
      cache-file = "/var/lib/ntfy-sh/cache.db";
      auth-file = "/var/lib/ntfy-sh/auth.db";
      auth-default-access = "deny-all";
      behind-proxy = true;
      base-url = "https://ntfy.nkagami.me";
      attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
      enable-login = true;
      enable-reservations = true;
      upstream-base-url = "https://ntfy.sh";
    };
  };
  systemd.services.ntfy-sh.serviceConfig = {
    WorkingDirectory = "/var/lib/ntfy-sh";
    StateDirectory = "ntfy-sh";
  };
  systemd.services.ntfy-sh.preStart = ''
    mkdir -p /var/lib/ntfy-sh/attachments
  '';
}

