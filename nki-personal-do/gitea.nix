{ pkgs, config, lib, ... }:
with lib;
let
  user = "gitea";
  host = "git.dtth.ch";
  port = 61116;

  secrets = config.sops.secrets;

  signingKey = "0x3681E15E5C14A241";

  catppuccinThemes = builtins.fetchurl {
    url = "https://github.com/catppuccin/gitea/releases/download/v0.2.1/catppuccin-gitea.tar.gz";
    sha256 = "sha256:18l67whffayrgylsf5j6g7sj95anjcjl0cy7fzqn1wrm0gg2xns0";
  };
  themes = strings.concatStringsSep "," [
    "catppuccin-macchiato-green"
    "catppuccin-mocha-teal"
    "catppuccin-macchiato-sky"
    "catppuccin-mocha-sky"
    "catppuccin-mocha-yellow"
    "catppuccin-mocha-lavender"
    "catppuccin-macchiato-rosewater"
    "catppuccin-macchiato-lavender"
    "catppuccin-macchiato-pink"
    "catppuccin-frappe-lavender"
    "catppuccin-macchiato-yellow"
    "catppuccin-frappe-yellow"
    "catppuccin-latte-red"
    "catppuccin-frappe-flamingo"
    "catppuccin-mocha-blue"
    "catppuccin-macchiato-peach"
    "catppuccin-macchiato-flamingo"
    "catppuccin-mocha-pink"
    "catppuccin-macchiato-mauve"
    "catppuccin-mocha-rosewater"
    "catppuccin-latte-rosewater"
    "catppuccin-mocha-red"
    "catppuccin-macchiato-sapphire"
    "catppuccin-latte-teal"
    "catppuccin-latte-flamingo"
    "catppuccin-macchiato-blue"
    "catppuccin-latte-blue"
    "catppuccin-latte-peach"
    "catppuccin-frappe-mauve"
    "catppuccin-frappe-green"
    "catppuccin-frappe-teal"
    "catppuccin-latte-mauve"
    "catppuccin-macchiato-teal"
    "catppuccin-frappe-red"
    "catppuccin-latte-yellow"
    "catppuccin-latte-lavender"
    "catppuccin-mocha-flamingo"
    "catppuccin-frappe-sapphire"
    "catppuccin-frappe-blue"
    "catppuccin-mocha-green"
    "catppuccin-frappe-maroon"
    "catppuccin-latte-green"
    "catppuccin-frappe-rosewater"
    "catppuccin-latte-sapphire"
    "catppuccin-frappe-sky"
    "catppuccin-mocha-sapphire"
    "catppuccin-mocha-maroon"
    "catppuccin-macchiato-red"
    "catppuccin-latte-pink"
    "catppuccin-frappe-peach"
    "catppuccin-frappe-pink"
    "catppuccin-mocha-mauve"
    "catppuccin-macchiato-maroon"
    "catppuccin-mocha-peach"
    "catppuccin-latte-sky"
    "catppuccin-latte-maroon"
  ];
in
{
  sops.secrets."gitea/signing-key".owner = user;
  sops.secrets."gitea/mailer-password".owner = user;
  # database
  cloud.postgresql.databases = [ user ];
  # traefik
  cloud.traefik.hosts.gitea = {
    inherit port host;
    noCloudflare = true;
  };

  services.gitea = {
    enable = true;
    package = pkgs.unstable.gitea;

    inherit user;

    domain = host;
    rootUrl = "https://${host}/";
    httpAddress = "127.0.0.1";
    httpPort = port;

    appName = "DTTHgit";

    settings = {
      repository = {
        DEFAULT_PRIVATE = "private";
        PREFERRED_LICENSES = strings.concatStringsSep "," [ "AGPL-3.0-or-later" "GPL-3.0-or-later" "Apache-2.0" ];
        DISABLE_HTTP_GIT = true;
        DEFAULT_BRANCH = "master";
        ENABLE_PUSH_CREATE_USER = true;
      };
      "repository.pull-request" = {
        DEFAULT_MERGE_STYLE = "squash";
      };
      "repository.signing" = {
        SIGNING_KEY = signingKey;
        SIGNING_NAME = "DTTHGit";
        SIGNING_EMAIL = "dtth-gitea@nkagami.me";
      };
      ui.THEMES = "auto,gitea,arc-green," + themes;
      "ui.meta" = {
        AUTHOR = "DTTHgit - Gitea instance for GTTH";
        DESCRIPTION = "DTTHGit is a custom Gitea instance hosted for DTTH members only.";
        KEYWORDS = "git,gitea,dtth";
      };
      service = {
        DISABLE_REGISTRATION = true;
        ENABLE_NOTIFY_MAIL = true;
        ENABLE_BASIC_AUTHENTICATION = false;
        REGISTER_EMAIL_CONFIRM = true;
      };
      "service.explore" = {
        REQUIRE_SIGNIN_VIEW = true;
      };
      session = {
        COOKIE_SECURE = true;
      };

      oauth2_client = {
        REGISTER_EMAIL_CONFIRM = false;
        ENABLE_AUTO_REGISTRATION = true;
      };

      mailer = {
        ENABLED = true;
        PROTOCOL = "smtps";
        SMTP_ADDR = "mx1.nkagami.me";
        SMTP_PORT = 465;
        USER = "dtth-gitea@nkagami.me";
        FROM = "DTTHGit <dtth-gitea@nkagami.me>";
      };

      git = {
        PATH = "${pkgs.git}/bin/git";
      };

      federation.ENABLED = true;
    };

    mailerPasswordFile = secrets."gitea/mailer-password".path;

    database = {
      inherit user;
      createDatabase = false;
      type = "postgres";
      socket = "/var/run/postgresql";
      name = user;
    };

    # LFS
    lfs.enable = true;

    # Backup
    # dump.enable = true;
  };

  # Set up gpg signing key
  systemd.services.gitea = {
    path = with pkgs; [ gnupg ];
    environment.GNUPGHOME = "${config.services.gitea.stateDir}/.gnupg";
    # https://github.com/NixOS/nixpkgs/commit/93c1d370db28ad4573fb9890c90164ba55391ce7
    serviceConfig.SystemCallFilter = mkForce "~@clock @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io @reboot @setuid @swap";
    preStart = ''
      # Import the signing subkey
      if cat ${config.services.gitea.stateDir}/.gnupg/gpg.conf | grep -q ${signingKey}; then
        echo "Keys already imported"
        # imported
      else
        echo "Import your keys!"
        ${pkgs.gnupg}/bin/gpg --quiet --import ${secrets."gitea/signing-key".path}
        echo "trusted-key ${signingKey}" >> ${config.services.gitea.stateDir}/.gnupg/gpg.conf
        exit 1
      fi

      # Copy icons
      mkdir -p ${config.services.gitea.stateDir}/custom/public/img
      install -m 0644 ${./gitea/img}/* ${config.services.gitea.stateDir}/custom/public/img

      # Copy the themes
      mkdir -p ${config.services.gitea.stateDir}/custom/public/css
      env PATH=${pkgs.gzip}/bin:${pkgs.gnutar}/bin:$PATH \
        tar -xvf ${catppuccinThemes} -C ${config.services.gitea.stateDir}/custom/public/css/
    '';
  };
}
