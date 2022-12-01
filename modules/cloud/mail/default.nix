{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.cloud.mail;

  name = "maddy";

  stateDir = "/var/lib/${name}";
  runtimeDir = "/run/${name}";

  smtpPort = 58787;
  smtpsPort = 46565;
  imapPort = 9333;
  mtaStsPort = 8003;
in
{
  options.cloud.mail = {
    enable = mkEnableOption "Enable the email server";

    debug = mkEnableOption "Enable debugging";

    package = mkOption {
      type = types.package;
      default = pkgs.maddy;
    };

    hostname = mkOption {
      type = types.str;
      default = "mx1.nkagami.me";
      description = "The hostname where the server is run on";
    };

    local_ip = mkOption {
      type = types.str;
      default = "";
      description = "The local IP address used as the sender IP during delivery";
    };

    primaryDomain = mkOption {
      type = types.str;
      default = "nkagami.me";
      description = "The primary email domain";
    };

    additionalDomains = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional domain names to be used";
    };

    tls = {
      certFile = mkOption {
        type = types.str;
        description = "Path to the certificate file.";
      };
      keyFile = mkOption {
        type = types.str;
        description = "Path to the key file.";
      };
    };

    usersFile = mkOption {
      type = types.path;
      description = ''
        The file containing user:hashed-password pairs to be used in the mail server.
        Check `maddyctl hash` to generate hashed passwords.
      '';
    };
  };

  config =
    let
      configFile = pkgs.writeText "maddy.conf" ''
        # Globals
        state_dir ${stateDir}
        runtime_dir ${runtimeDir}

        # Base variables

        $(hostname) = ${cfg.hostname}
        $(primary_domain) = ${cfg.primaryDomain}
        $(local_domains) = ${cfg.primaryDomain} ${lib.strings.concatStringsSep " " cfg.additionalDomains}

        tls file "${cfg.tls.certFile}" "${cfg.tls.keyFile}"

        # Authentication
        auth.pass_table local_authdb {
            table file ${cfg.usersFile}
        }

        # Local storage
        storage.imapsql local_mailboxes {
            driver "postgres"
            dsn "dbname='${name}' user='${name}' host='/run/postgresql' sslmode=disable"
            appendlimit 256M
        }

        # ----------------------------------------------------------------------------
        # SMTP endpoints + message routing

        hostname $(hostname)

        msgpipeline local_routing {
            # Insert handling for special-purpose local domains here.
            # e.g.
            # destination lists.example.org {
            #     deliver_to lmtp tcp://127.0.0.1:8024
            # }

            destination postmaster $(local_domains) {
                modify {
                    replace_rcpt regexp "(.+)\+(.+)@(.+)" "$1@$3"
                    replace_rcpt file /etc/maddy/aliases
                }

                deliver_to &local_mailboxes
            }

            default_destination {
                reject 550 5.1.1 "User doesn't exist"
            }
        }

        smtp tcp://0.0.0.0:25 {
            limits {
                # Up to 20 msgs/sec across max. 10 SMTP connections.
                all rate 20 1s
                all concurrency 10
            }

            dmarc yes
            check {
                require_mx_record
                dkim
                spf
            }

            source $(local_domains) {
                reject 501 5.1.8 "Use Submission for outgoing SMTP"
            }
            default_source {
                destination postmaster $(local_domains) {
                    deliver_to &local_routing
                }
                default_destination {
                    reject 550 5.1.1 "User doesn't exist"
                }
            }
        }

        submission tcp://0.0.0.0:${toString smtpPort} tls://0.0.0.0:${toString smtpsPort} {
            limits {
                # Up to 50 msgs/sec across any amount of SMTP connections.
                all rate 50 1s
            }

            auth &local_authdb

            source $(local_domains) {
                destination postmaster $(local_domains) {
                    deliver_to &local_routing
                }
                default_destination {
                    modify {
                        dkim $(primary_domain) $(local_domains) default
                    }
                    deliver_to &remote_queue
                }
            }
            default_source {
                reject 501 5.1.8 "Non-local sender domain"
            }
        }

        target.remote outbound_delivery {
            limits {
                # Up to 20 msgs/sec across max. 10 SMTP connections
                # for each recipient domain.
                destination rate 20 1s
                destination concurrency 10
            }
            mx_auth {
                dane
                # mtasts {
                #     cache fs
                #     fs_dir mtasts_cache/
                # }
                local_policy {
                    min_tls_level encrypted
                    min_mx_level none
                }
            }
            ${if cfg.local_ip == "" then "" else "local_ip ${cfg.local_ip}"}
        }

        target.queue remote_queue {
            target &outbound_delivery

            autogenerated_msg_domain $(primary_domain)
            bounce {
                destination postmaster $(local_domains) {
                    deliver_to &local_routing
                }
                default_destination {
                    reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
                }
            }
        }

        # ----------------------------------------------------------------------------
        # IMAP endpoints

        imap tls://0.0.0.0:${toString imapPort} {
            auth &local_authdb
            storage &local_mailboxes
        }
      '';

      mtaStsDir = pkgs.writeTextDir ".well-known/mta-sts.txt" ''
        version: STSv1
        mode: enforce
        max_age: 604800
        mx: ${cfg.hostname}
      '';
    in
    mkIf cfg.enable {
      # users
      users.users."${name}" = {
        group = "${name}";
        isSystemUser = true;
      };
      users.groups."${name}" = { };

      # database
      cloud.postgresql.databases = [ name ];

      # MTA-STS server
      services.nginx.enable = true;
      services.nginx.virtualHosts.maddy-mta-sts = {
        listen = [{ addr = "127.0.0.1"; port = mtaStsPort; }];
        root = mtaStsDir;
      };

      # Firewall
      networking.firewall.allowedTCPPorts = [ 25 ];

      # traefik
      cloud.traefik.hosts.maddy-smtp = {
        protocol = "tcp";
        port = smtpPort;
        host = "mx1.nkagami.me";
        tlsPassthrough = false;
        entrypoints = [ "smtp-submission" ];
      };
      cloud.traefik.hosts.maddy-smtps = {
        protocol = "tcp";
        port = smtpsPort;
        host = "mx1.nkagami.me";
        entrypoints = [ "smtp-submission-ssl" ];
      };
      cloud.traefik.hosts.maddy-imap = {
        protocol = "tcp";
        port = imapPort;
        host = "mx1.nkagami.me";
        entrypoints = [ "imap" ];
      };
      cloud.traefik.hosts.maddy-mta-sts = {
        port = mtaStsPort;
        host = "mta-sts.nkagami.me";
      };

      # maddy itself
      systemd.services."${name}" = {
        after = [ "network.target" "traefik-certs-dumper.service" ];
        wantedBy = [ "multi-user.target" ];

        description = "maddy mail server";
        documentation = [
          "man:maddy(1)"
          "man:maddy.conf(5)"
          "https://maddy.email"
        ];

        serviceConfig = {
          Type = "notify";
          NotifyAccess = "exec";

          User = name;
          Group = name;

          WorkingDirectory = "/var/lib/${name}";

          ConfigurationDirectory = name;
          RuntimeDirectory = name;
          StateDirectory = name;
          LogsDirectory = name;
          ReadOnlyPaths = "/usr/lib/${name} ${cfg.tls.keyFile} ${cfg.tls.certFile}";
          ReadWritePaths = "/var/lib/${name}";

          # Strict sandboxing. You have no reason to trust code written by strangers from GitHub.
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ProtectKernelTunables = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";

          # Additional sandboxing. You need to disable all of these options
          # for privileged helper binaries (for system auth) to work correctly.
          NoNewPrivileges = true;
          PrivateDevices = true;
          DeviceAllow = "/dev/syslog";
          RestrictSUIDSGID = true;
          ProtectKernelModules = true;
          MemoryDenyWriteExecute = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          LockPersonality = true;

          # Graceful shutdown with a reasonable timeout.
          TimeoutStopSec = "7s";
          KillMode = "mixed";
          KillSignal = "SIGTERM";


          # Required to bind on ports lower than 1024.
          AmbientCapabilities = "CAP_NET_BIND_SERVICE";
          CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";

          # Bump FD limitations. Even idle mail server can have a lot of FDs open (think
          # of idle IMAP connections, especially ones abandoned on the other end and
          # slowly timing out).
          LimitNOFILE = 131072;

          # Limit processes count to something reasonable to
          # prevent resources exhausting due to big amounts of helper
          # processes launched.
          LimitNPROC = 512;

          # Restart server on any problem.
          Restart = "on-failure";
          # ... Unless it is a configuration problem.
          RestartPreventExitStatus = 2;

          ExecStart = "${cfg.package}/bin/maddy ${if cfg.debug then "-debug " else ""}-config ${configFile}";
        };
        reload = ''
          /bin/kill -USR1 $MAINPID
          /bin/kill -USR2 $MAINPID
        '';
      };
    };
}
