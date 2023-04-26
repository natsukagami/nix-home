{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.common.linux;

  # Modules
  modules = {
    adb = { config, ... }: mkIf config.common.linux.enable {
      services.udev.packages = with pkgs; [ android-udev-rules ];
      programs.adb.enable = true;
      users.users.${config.common.linux.username}.extraGroups = [ "adbusers" ];
    };
    ios = { config, ... }: mkIf config.common.linux.enable {
      services.usbmuxd.enable = true;
      users.users.${config.common.linux.username}.extraGroups = [ config.services.usbmuxd.group ];
      systemd.network.networks."05-ios-tethering" = {
        matchConfig.Driver = "ipheth";
        networkConfig.DHCP = "yes";
      };
    };

    wlr = { ... }: mkIf config.common.linux.enable {
      # swaync disable notifications on screencast
      xdg.portal.wlr.settings.screencast = {
        exec_before = ''which swaync-client && swaync-client --inhibitor-add "xdg-desktop-portal-wlr" || true'';
        exec_after = ''which swaync-client && swaync-client --inhibitor-remove "xdg-desktop-portal-wlr" || true'';
      };
    };

    logitech = { pkgs, ... }: mkIf cfg.enable {
      services.ratbagd.enable = true;
      environment.systemPackages = with pkgs; [ piper ];
    };
  };
in
{
  imports = with modules; [ adb ios wlr logitech ];

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
        default = [ "8.8.8.8" "8.8.4.4" ];
      };
      networks = mkOption {
        type = types.attrsOf (types.submodule {
          options.match = mkOption {
            type = types.str;
            description = "The interface name to match";
          };
          options.isRequired = mkOption {
            type = types.bool;
            description = "Require this interface to be connected for network-online.target";
            default = false;
          };
        });
        description = "Network configuration";
        default = {
          default = { match = "*"; };
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
      plymouth.enable = true;
      loader.timeout = 60;
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      supportedFilesystems = [ "ntfs" ];
    };
    boot.initrd.systemd.enable = builtins.length (builtins.attrNames (cfg.luksDevices)) > 0;
    # LUKS devices
    boot.initrd.luks.devices = builtins.mapAttrs
      (name: path: {
        device = path;
        preLVM = true;
        allowDiscards = true;

        crypttabExtraOpts = [
          "tpm2-device=auto"
          "fido2-device=auto"
        ];
      })
      cfg.luksDevices;

    ## Hardware-related
    # Enable sound.
    sound.enable = true;
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
    # Bluetooth: just enable
    hardware.bluetooth.enable = true;
    hardware.bluetooth.package = pkgs.bluez5-experimental; # Why do we need experimental...?
    hardware.bluetooth.settings.General.Experimental = true;
    services.blueman.enable = true; # For a GUI

    ## Users
    users.users.${cfg.username} = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
        "plugdev" # Enable openrazer-daemon privileges
      ];
    };

    ## Network configuration
    systemd.network.enable = true;
    networking.hostName = cfg.networking.hostname;
    networking.wireless.iwd.enable = true;
    systemd.network.networks = builtins.mapAttrs
      (name: cfg: {
        matchConfig.Name = cfg.match;
        networkConfig.DHCP = "yes";
        linkConfig.RequiredForOnline = if cfg.isRequired then "yes" else "no";
      })
      cfg.networking.networks;
    # Leave DNS to systemd-resolved
    services.resolved.enable = true;
    services.resolved.domains = cfg.networking.dnsServers;
    services.resolved.fallbackDns = cfg.networking.dnsServers;
    # Firewall: only open to SSH now
    networking.firewall.allowedTCPPorts = [ 22 ];
    networking.firewall.allowedUDPPorts = [ 22 ];

    ## Time and Region
    time.timeZone = "Europe/Zurich";
    # Select internationalisation properties.
    console.keyMap = "jp106"; # Console key layout
    i18n.defaultLocale = "ja_JP.UTF-8";
    # Input methods (only fcitx5 works reliably on Wayland)
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-unikey
        fcitx5-gtk
      ];
    };

    # Default packages
    environment.systemPackages = with pkgs; [
      kakoune # An editor
      wget # A simple fetcher
      fish # Good shell

      ## System monitoring tools
      usbutils # lsusb and friends
      pciutils # lspci and friends
      psmisc # killall, pstree, ...

      ## Security stuff
      libsForQt5.qtkeychain

      ## Wayland
      qt5.qtwayland
    ];
    # Add a reliable terminal
    programs.gnome-terminal.enable = true;
    # KDEConnect is just based
    programs.kdeconnect.enable = true;
    # Flatpaks are useful... sometimes...
    services.flatpak.enable = true;
    # DConf for GNOME configurations
    programs.dconf.enable = true;
    # Gaming! (not for ARM64)
    programs.steam.enable = !pkgs.stdenv.isAarch64;
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;
    hardware.opengl.driSupport32Bit = !pkgs.stdenv.isAarch64; # For 32 bit applications
    # Email
    programs.evolution = {
      enable = true;
      plugins = with pkgs; [ evolution-ews ]; # For @epfl.ch and @uwaterloo.ca emails
    };


    ## Services
    # gnome-keyring for storing keys
    services.gnome.gnome-keyring.enable = true;
    # OpenSSH so you can SSH to me
    services.openssh.enable = true;
    # PAM
    security.pam.services.login.enableKwallet = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.pam.services.lightdm.enableKwallet = true;
    security.pam.services.lightdm.enableGnomeKeyring = true;
    security.pam.services.swaylock = { };
    # Printers
    services.printing.enable = true;
    # Portals
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      # gtk portal needed to make gtk apps happy
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
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
