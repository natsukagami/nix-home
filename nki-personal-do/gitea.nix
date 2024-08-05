{ pkgs, config, lib, ... }:
with lib;
let
  user = "gitea";
  host = "git.dtth.ch";
  port = 61116;

  secrets = config.sops.secrets;

  signingKey = "0x3681E15E5C14A241";

  catppuccinThemes = pkgs.fetchurl {
    url = "https://github.com/catppuccin/gitea/releases/download/v0.4.1/catppuccin-gitea.tar.gz";
    hash = "sha256-/P4fLvswitlfeaKaUykrEKvjbNpw5Q/nzGQ/GZaLyUI=";
  };
  staticDir = pkgs.runCommandLocal "forgejo-static" { } ''
    mkdir -p $out
    tmp=$(mktemp -d)
    cp -r ${config.services.forgejo.package.data}/* $tmp
    chmod -R +w $tmp

    # Copy icons
    install -m 0644 ${./gitea/img}/* $tmp/public/assets/img

    # Copy the themes
    env PATH=${pkgs.gzip}/bin:${pkgs.gnutar}/bin:$PATH \
      tar -xvf ${catppuccinThemes} -C $tmp/public/assets/css

    cp -r $tmp/* $out
  '';

  default-themes = "forgejo-auto, forgejo-light, forgejo-dark, gitea-auto, gitea-light, gitea-dark, forgejo-auto-deuteranopia-protanopia, forgejo-light-deuteranopia-protanopia, forgejo-dark-deuteranopia-protanopia, forgejo-auto-tritanopia, forgejo-light-tritanopia, forgejo-dark-tritanopia";
  themes = strings.concatStringsSep ", " [
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
  users.users.${user} = {
    home = config.services.forgejo.stateDir;
    useDefaultShell = true;
    isSystemUser = true;
    group = user;
  };
  users.groups.${user} = { };
  sops.secrets."gitea/signing-key".owner = user;
  sops.secrets."gitea/mailer-password".owner = user;
  # database
  cloud.postgresql.databases = [ user ];
  # traefik
  cloud.traefik.hosts.gitea = {
    inherit port host;
    noCloudflare = true;
  };

  systemd.services.forgejo.requires = [ "postgresql.service" ];

  services.forgejo = {
    enable = true;

    inherit user;

    settings = {
      server = {
        DOMAIN = host;
        ROOT_URL = "https://${host}/";
        HTTP_ADDRESS = "127.0.0.1";
        HTTP_PORT = port;
        STATIC_ROOT_PATH = staticDir;
      };
      repository = {
        DEFAULT_PRIVATE = "private";
        PREFERRED_LICENSES = strings.concatStringsSep "," [ "AGPL-3.0-or-later" "GPL-3.0-or-later" "Apache-2.0" ];
        # DISABLE_HTTP_GIT = true;
        DEFAULT_BRANCH = "master";
        ENABLE_PUSH_CREATE_USER = true;
      };
      "repository.pull-request" = {
        DEFAULT_MERGE_STYLE = "squash";
      };
      "repository.signing" = {
        SIGNING_KEY = signingKey;
        SIGNING_NAME = "DTTHgit";
        SIGNING_EMAIL = "dtth-gitea@nkagami.me";
      };
      ui.THEMES = default-themes + "," + themes;
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
      DEFAULT.APP_NAME = "DTTHGit";
    };

    stateDir = "/mnt/data/gitea";

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
  systemd.services.forgejo = {
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
    '';
  };
}
