{ pkgs, config, ... }: {
  imports = [
    ./hardware-configuration.nix

    # Set up cloud
    ../modules/cloud/postgresql
    ../modules/cloud/traefik
    ../modules/cloud/bitwarden
    ../modules/cloud/mail
  ];

  boot.cleanTmpDir = true;
  networking.hostName = "nki-personal";
  networking.firewall.allowPing = true;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLr1Q+PJuDYJtBAVMSU0U2kZi4V0Z7dE+dpRxa4aEDupSlcPCwSEtcpNME1up7z0yxjcIHHkBYq0RobIaLqwEmntnZzz37jg/iiHwyZsN93jZljId1X0uykcMem4ljiqgmRg3Fs8RKj2+N1ovpIZVDOWINLJJDVJntNvwW/anSCtx27FATVdroHoiyXCwVknG6p3bHU5Nd3idRMn45kZ7Qf1J50XUhtu3ehIWI2/5nYIbi8WDnzY5vcRZEHROyTk2pv/m9rRkCTaGnUdZsv3wfxeeT3223k0mUfRfCsiPtNDGwXn66HcG2cmhrBIeDoZQe4XNkzspaaJ2+SGQfO8Zf natsukagami@gmail.com"
  ];

  environment.systemPackages = with pkgs; [
    git
  ];

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
  sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];

  # tinc
  services.my-tinc.enable = true;
  services.my-tinc.hostName = "cloud";
  sops.secrets.tinc-private-key = { };
  services.my-tinc.rsaPrivateKey = config.sops.secrets.tinc-private-key.path;

  # Set up traefik
  sops.secrets.cloudflare-dns-api-token = { owner = "traefik"; };
  sops.secrets.traefik-dashboard-users = { owner = "traefik"; };
  cloud.traefik.cloudflareKeyFile = config.sops.secrets.cloudflare-dns-api-token.path;
  cloud.traefik.dashboard = {
    enable = true;
    usersFile = config.sops.secrets.traefik-dashboard-users.path;
  };
  cloud.traefik.certsDumper.enable = true;

  # Mail
  sops.secrets.mail-users = { owner = "maddy"; };
  cloud.mail = {
    enable = true;
    debug = true;
    tls.certFile = "${config.cloud.traefik.certsDumper.destination}/${config.cloud.mail.hostname}/certificate.crt";
    tls.keyFile = "${config.cloud.traefik.certsDumper.destination}/${config.cloud.mail.hostname}/privatekey.key";
    usersFile = config.sops.secrets.mail-users.path;
  };

  # Youmubot
  sops.secrets.youmubot-env = {};
  services.youmubot = {
    enable = true;
    envFile = config.sops.secrets.youmubot-env.path;
  };
}
