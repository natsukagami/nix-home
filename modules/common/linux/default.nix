{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.common.linux;

  # Modules
  modules = {
    adb =
      { config, ... }:
      mkIf config.common.linux.enable {
        services.udev.packages = with pkgs; [ android-udev-rules ];
        programs.adb.enable = true;
        users.users.${config.common.linux.username}.extraGroups = [ "adbusers" ];
      };
    ios =
      { config, pkgs, ... }:
      mkIf config.common.linux.enable {
        services.usbmuxd.enable = true;
        services.usbmuxd.package = pkgs.usbmuxd2;
        environment.systemPackages = with pkgs; [
          libimobiledevice
          ifuse
        ];
        users.users.${config.common.linux.username}.extraGroups = [ config.services.usbmuxd.group ];
        systemd.network.networks."05-ios-tethering" = {
          matchConfig.Driver = "ipheth";
          networkConfig.DHCP = "yes";
          linkConfig.RequiredForOnline = "no";
        };
      };

    graphics =
      { config, pkgs, ... }:
      {
        hardware.graphics.enable = true;
        hardware.graphics.enable32Bit = true;
        # Monitor backlight
        hardware.i2c.enable = true;
        services.ddccontrol.enable = true;
        environment.systemPackages = [
          pkgs.luminance
          pkgs.ddcutil
        ];
      };

    accounts =
      { pkgs, ... }:
      mkIf (config.common.linux.enable && !pkgs.stdenv.isAarch64) {
        environment.systemPackages = [
          pkgs.glib
          (pkgs.gnome-control-center or pkgs.gnome.gnome-control-center)
        ];
        services.accounts-daemon.enable = true;
        services.gnome.gnome-online-accounts.enable = true;
        # programs.evolution.enable = true;
        # programs.evolution.plugins = with pkgs; [ evolution-ews ];
        # services.gnome.evolution-data-server.enable = true;
        # services.gnome.evolution-data-server.plugins = with pkgs; [ evolution-ews ];
      };

    wlr =
      { lib, config, ... }:
      mkIf config.common.linux.enable {
        # swaync disable notifications on screencast
        xdg.portal.wlr.settings.screencast = {
          exec_before = ''which swaync-client && swaync-client --inhibitor-add "xdg-desktop-portal-wlr" || true'';
          exec_after = ''which swaync-client && swaync-client --inhibitor-remove "xdg-desktop-portal-wlr" || true'';
        };

        # Niri stuff
        # https://github.com/sodiboo/niri-flake/blob/main/docs.md
        programs.niri.enable = true;
        programs.niri.package = pkgs.niri-stable;
        # Override gnome-keyring disabling
        services.gnome.gnome-keyring.enable = lib.mkForce false;
      };

    logitech =
      { pkgs, ... }:
      mkIf cfg.enable {
        services.ratbagd.enable = true;
        environment.systemPackages = with pkgs; [ piper ];
      };

    kwallet =
      { pkgs, lib, ... }:
      mkIf cfg.enable {
        environment.systemPackages = [ pkgs.kdePackages.kwallet ];
        services.dbus.packages = [ pkgs.kdePackages.kwallet ];
        xdg.portal = {
          extraPortals = [ pkgs.kdePackages.kwallet ];
        };
      };

    virtualisation =
      { pkgs, ... }:
      mkIf cfg.enable {
        virtualisation.podman = {
          enable = true;
          extraPackages = [ pkgs.slirp4netns ];
          dockerCompat = true;
          defaultNetwork.settings.dns_enabled = true;
        };

        virtualisation.oci-containers.backend = "podman";

        virtualisation.virtualbox.host.enable = false;
        users.extraGroups.vboxusers.members = [ cfg.username ];
      };
  };

  rt-audio =
    { pkgs, ... }:
    mkIf cfg.enable {
      services.pipewire.lowLatency = {
        # enable this module
        enable = true;
        # defaults (no need to be set unless modified)
        quantum = 32;
        rate = 44100;
      };
      security.rtkit.enable = true;

      # Real time configurations
      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "fs.inotify.max_user_watches" = 524288;
      };
      security.pam.loginLimits = [
        {
          domain = "@audio";
          item = "rtprio";
          type = "-";
          value = "90";
        }
        {
          domain = "@audio";
          item = "memlock";
          type = "-";
          value = "unlimited";
        }
      ];
    };
in
{
  imports = with modules; [
    ./sops.nix

    adb
    ios
    graphics
    wlr
    logitech
    kwallet
    virtualisation
    accounts
    rt-audio
  ];

  options.common.linux = {
    enable = mkOption {
      type = types.bool;
      description = "Enable the common settings for Linux personal machines";
      default = pkgs.stdenv.isLinux;
    };

    luksDevices = mkOption {
      type = types.attrsOf types.str;
      description = "A mapping from device mount name to its path (/dev/disk/...) to be mounted on boot";
      default = { };
    };

    networking = {
      hostname = mkOption {
        type = types.str;
        description = "Host name for your machine";
      };
      dnsServers = mkOption {
        type = types.listOf types.str;
        description = "DNS server list";
        default = [
          "1.1.1.1"
          "2606:4700:4700:1111"
        ];
      };
      networks = mkOption {
        type = types.attrsOf (
          types.submodule {
            options.match = mkOption {
              type = types.str;
              description = "The interface name to match";
            };
            options.isRequired = mkOption {
              type = types.bool;
              description = "Require this interface to be connected for network-online.target";
              default = false;
            };
          }
        );
        description = "Network configuration";
        default = {
          default = {
            match = "*";
          };
        };
      };
    };

    username = mkOption {
      type = types.str;
      description = "The linux username";
      default = "nki";
    };
  };

  config = mkIf cfg.enable {
    ## Boot Configuration
    # Set kernel version to latest
    boot.kernelPackages = mkDefault pkgs.linuxPackages_latest;
    # Use the systemd-boot EFI boot loader.
    boot = {
      loader.timeout = 60;
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      supportedFilesystems.ntfs = true;
    };
    boot.initrd.systemd.enable = builtins.length (builtins.attrNames (cfg.luksDevices)) > 0;
    # LUKS devices
    boot.initrd.luks.devices = builtins.mapAttrs (name: path: {
      device = path;
      preLVM = true;
      allowDiscards = true;

      crypttabExtraOpts = [
        "tpm2-device=auto"
        "fido2-device=auto"
      ];
    }) cfg.luksDevices;

    ## Hardware-related

    # Firmware stuff
    services.fwupd.enable = true;

    # Enable sound.
    services.pipewire = {
      enable = true;
      # alsa is optional
      alsa.enable = true;
      alsa.support32Bit = true;

      pulse.enable = true;
    };

    # udev configurations
    services.udev.packages = with pkgs; [
      qmk-udev-rules # For keyboards
    ];
    # udisks
    services.udisks2.enable = true;
    # Bluetooth: just enable
    hardware.bluetooth.enable = true;
    hardware.bluetooth.package = pkgs.bluez5-experimental; # Why do we need experimental...?
    hardware.bluetooth.settings.General.Experimental = true;
    services.blueman.enable = true; # For a GUI
    # ZRAM
    zramSwap.enable = true;

    ## Users
    users.users.${cfg.username} = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
        "plugdev" # Enable openrazer-daemon privileges
        "audio"
        "video"
        "input"
      ];
      shell = pkgs.fish;
    };
    nix.settings.trusted-users = [
      "root"
      cfg.username
    ];

    ## Network configuration
    systemd.network.enable = true;
    networking.dhcpcd.enable = lib.mkForce false;
    networking.useDHCP = false;
    networking.useNetworkd = true;
    systemd.network.wait-online.enable = false;
    networking.hostName = cfg.networking.hostname;
    networking.wireless.iwd.enable = true;
    networking.wireless.iwd.settings.General.EnableNetworkConfiguration = true;
    systemd.network.networks = builtins.mapAttrs (name: cfg: {
      matchConfig.Name = cfg.match;
      networkConfig.DHCP = "yes";
      linkConfig.RequiredForOnline = if cfg.isRequired then "yes" else "no";
    }) cfg.networking.networks;
    # Leave DNS to systemd-resolved
    services.resolved.enable = true;
    services.resolved.domains = cfg.networking.dnsServers;
    services.resolved.fallbackDns = cfg.networking.dnsServers;
    # Firewall: only open to SSH now
    networking.firewall.allowedTCPPorts = [ 22 ];
    networking.firewall.allowedUDPPorts = [ 22 ];
    # Enable tailscale
    services.tailscale.enable = true;

    ## Time and Region
    time.timeZone = lib.mkDefault "Europe/Zurich";
    # Select internationalisation properties.
    console.keyMap = "jp106"; # Console key layout
    i18n.defaultLocale = "ja_JP.UTF-8";
    # Input methods (only fcitx5 works reliably on Wayland)
    i18n.inputMethod =
      {
        fcitx5.waylandFrontend = true;
        fcitx5.addons = with pkgs; [
          fcitx5-mozc
          fcitx5-unikey
          fcitx5-gtk
        ];
      }
      // (
        if config.system.nixos.release == "24.05" then
          {
            enabled = "fcitx5";
          }
        else
          {
            enable = true;
            type = "fcitx5";
          }
      );

    # Default packages
    environment.systemPackages = with pkgs; [
      kakoune # An editor
      wget # A simple fetcher

      ## System monitoring tools
      usbutils # lsusb and friends
      pciutils # lspci and friends
      psmisc # killall, pstree, ...
      lm_sensors # sensors

      ## Security stuff
      libsForQt5.qtkeychain

      ## Wayland
      kdePackages.qtwayland
    ];
    # Add a reliable terminal
    programs.fish.enable = true;
    # programs.gnome-terminal.enable = true;
    # KDEConnect is just based
    programs.kdeconnect.enable = true;
    # Flatpaks are useful... sometimes...
    services.flatpak.enable = true;
    # AppImages should run
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
    # DConf for GNOME configurations
    programs.dconf.enable = true;
    # Gaming! (not for ARM64)
    programs.steam.enable = true;
    programs.gamescope = {
      enable = true;
      # capSysNice = true; # https://github.com/NixOS/nixpkgs/issues/351516
      args = [
        "--adaptive-sync"
        "--rt"
      ];
    };

    ## Services
    # OpenSSH so you can SSH to me
    services.openssh.enable = true;
    # PAM
    security.pam.services.login.enableKwallet = true;
    security.pam.services.lightdm.enableKwallet = true;
    security.pam.services.swaylock = { };
    # Printers
    services.printing.enable = true;
    # Portals
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      # gtk portal needed to make gtk apps happy
      extraPortals = [
        pkgs.kdePackages.xdg-desktop-portal-kde
        pkgs.xdg-desktop-portal-gtk
      ];

      config.sway.default = [
        "wlr"
        "kde"
        "kwallet"
      ];
      config.niri = {
        default = [
          "kde"
          "gnome"
          "gtk"
        ];
        # "org.freedesktop.impl.portal.Access" = "gtk";
        # "org.freedesktop.impl.portal.Notification" = "gtk";
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Secret" = "kwallet";
        "org.freedesktop.impl.portal.FileChooser" = "kde";
      };
    };
    # D-Bus
    services.dbus.packages = with pkgs; [ gcr ];

    ## Environment
    environment.variables = {
      # Set default editor
      EDITOR = "kak";
      VISUAL = "kak";
    };
  };
}
