# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
let
  openrazer =
    { pkgs, ... }:
    {
      # Razer stuff
      hardware.openrazer = {
        enable = true;
        users = [ "nki" ];
      };
      environment.systemPackages = with pkgs; [ polychromatic ];
    };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Fonts
    ../modules/personal/fonts
    # Encrypted DNS
    ../modules/services/edns
    # Other services
    ../modules/personal/u2f.nix
    ./peertube-runner.nix
    openrazer
  ];

  config = mkMerge [
    {

      # Kernel
      boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;

      # Plasma!
      services.desktopManager.plasma6.enable = true;

      ## Encryption
      # Kernel modules needed for mounting USB VFAT devices in initrd stage
      common.linux.luksDevices.root = "/dev/disk/by-uuid/7c6e40a8-900b-4f85-9712-2b872caf1892";
      common.linux.sops.enable = true;
      common.linux.sops.file = ./secrets.yaml;

      # Nix cache server
      sops.secrets."nix-cache/private-key" = {
        owner = "harmonia";
        group = "harmonia";
        mode = "0600";
      };
      nki.services.nix-cache = {
        enableServer = true;
        privateKeyFile = config.sops.secrets."nix-cache/private-key".path;
      };

      sops.secrets."nix-build-farm/private-key" = {
        mode = "0400";
      };
      services.nix-build-farm.hostname = "home";
      services.nix-build-farm.privateKeyFile = config.sops.secrets."nix-build-farm/private-key".path;

      # Networking
      common.linux.networking = {
        hostname = "kagamiPC"; # Define your hostname.
        networks = {
          "10-wired" = {
            match = "enp*";
            isRequired = true;
          };
          "20-wireless".match = "wlan*";
        };
        dnsServers = [ "127.0.0.1" ];
      };
      nki.services.edns.enable = true;
      nki.services.edns.ipv6 = true;
      ## DTTH Wireguard
      #
      sops.secrets."wg-dtth/private-key" = {
        owner = "root";
        group = "systemd-network";
        mode = "0640";
      };
      sops.secrets."wg-dtth/preshared-key" = {
        owner = "root";
        group = "systemd-network";
        mode = "0640";
      };
      systemd.network.netdevs."10-wg-dtth" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg-dtth";
          MTUBytes = "1280";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets."wg-dtth/private-key".path;
        };
        wireguardPeers = [
          {
            PublicKey = "+7iI4jwmM1Qr+/DKB1Hv8JgFkGu7lSV0PAoo+O5d3yQ=";
            PresharedKeyFile = config.sops.secrets."wg-dtth/preshared-key".path;
            AllowedIPs = [
              "100.64.0.0/10"
              "fd00::/106"
            ];
            Endpoint = "vpn.dtth.ch:51820";
            PersistentKeepalive = 25;
          }
        ];
      };
      systemd.network.networks."wg-dtth" = {
        matchConfig.Name = "wg-dtth";
        address = [
          "100.73.146.80/32"
          "fd00::33:105b/128"
        ];
        DHCP = "no";
        routes = [
          {
            Destination = "100.64.0.0/10";
            Scope = "link";
          }
          { Destination = "fd00::/106"; }
        ];
      };

      # Define a user account.
      common.linux.username = "nki";
      services.getty.autologinUser = "nki";

      ## Hardware
      # Peripherals
      hardware.opentabletdriver.enable = true;
      # Enable razer daemon
      hardware.openrazer.enable = true;
      hardware.openrazer.keyStatistics = true;
      hardware.openrazer.verboseLogging = true;

      # Mounting disks!
      fileSystems =
        let
          ntfsMount = path: {
            device = path;
            fsType = "ntfs";
            options = [
              "rw"
              "uid=${toString config.users.users.nki.uid}"
              "nofail"
            ];
          };
        in
        {
          "/mnt/Data" = ntfsMount "/dev/disk/by-uuid/A90680F8BBE62FE3";
          "/mnt/Stuff" = ntfsMount "/dev/disk/by-uuid/717BF2EE20BB8A62";
          "/mnt/Shared" = ntfsMount "/dev/disk/by-uuid/76AC086BAC0827E7";
          "/mnt/osu" = ntfsMount "/dev/disk/by-uuid/530D3E1648CD1C26";
        };

      # PAM
      personal.u2f.enable = true;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "22.11"; # Did you read the comment?

      # tinc network
      sops.secrets."tinc/ed25519-private-key" = { };
      sops.secrets."tinc/rsa-private-key" = { };
      services.my-tinc = {
        enable = true;
        hostName = "home";
        rsaPrivateKey = config.sops.secrets."tinc/rsa-private-key".path;
        ed25519PrivateKey = config.sops.secrets."tinc/ed25519-private-key".path;
        bindPort = 6565;
      };

      # Music server
      services.navidrome.enable = true;
      services.navidrome.settings = {
        Address = "11.0.0.2";
        MusicFolder = "/mnt/Stuff/Music";
      };
      systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = lib.mkAfter [ "/etc" ];
      networking.firewall.allowedTCPPorts = [
        4533
        8000
      ];

      # Printers
      services.printing.enable = true;

      # mpd
      services.mpd = {
        enable = true;
        user = "nki";
        startWhenNeeded = true;
        extraConfig = ''
          audio_output {
            type "pipewire"
            name "pipewire local"
            dsd "yes"
          }
        '';
      };
      systemd.services.mpd.environment = {
        # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
        XDG_RUNTIME_DIR = "/run/user/1000"; # User-id 1000 must match above user. MPD will look inside this directory for the PipeWire socket.
      };
      sops.secrets."scrobble/lastfm" = { };
      sops.secrets."scrobble/listenbrainz" = { };
      services.mpdscribble = {
        enable = true;
        endpoints."last.fm" = {
          username = "natsukagami";
          passwordFile = config.sops.secrets."scrobble/lastfm".path;
        };
        endpoints."listenbrainz" = {
          username = "natsukagami";
          passwordFile = config.sops.secrets."scrobble/listenbrainz".path;
        };
      };

      programs.virt-manager.enable = true;

      users.groups.libvirtd.members = [ "nki" ];

      virtualisation.libvirtd.enable = true;

      virtualisation.spiceUSBRedirection.enable = true;
    }
    {
      # LLM poop
      services.ollama = {
        enable = true;
        loadModels = [
          "deepseek-r1:14b"
          "gemma3:12b"
        ];
        acceleration = "rocm";
        rocmOverrideGfx = "10.3.1";
      };
      systemd.services.ollama = {
        serviceConfig.LimitMEMLOCK = "${toString (16 * 1024 * 1024 * 1024)}";
      };
      services.open-webui = {
        enable = true;
        port = 5689;
        openFirewall = true;
        host = "0.0.0.0";
        environment = {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          ENV = "prod";
          ENABLE_SIGNUP = "false";
        };
      };
      common.linux.tailscale.firewall.allowPorts = [ config.services.open-webui.port ];
    }
  ];
}
