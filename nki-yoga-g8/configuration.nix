# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  vmware = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.vmware-horizon-client ];
    virtualisation.vmware.host = {
      enable = true;
    };
  };
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Fonts
      ../modules/personal/fonts
      # Encrypted DNS
      ../modules/services/edns

      vmware
    ];

  # Secrets
  common.linux.sops.enable = true;
  common.linux.sops.file = ./secrets.yaml;

  # Build farm
  sops.secrets."nix-build-farm/private-key" = { mode = "0400"; };
  services.nix-build-farm.hostname = "yoga";
  services.nix-build-farm.privateKeyFile = config.sops.secrets."nix-build-farm/private-key".path;

  ## tinc
  sops.secrets."tinc-private-key" = { };
  services.my-tinc = {
    enable = true;
    hostName = "yoga";
    ed25519PrivateKey = config.sops.secrets."tinc-private-key".path;
  };

  services.desktopManager.plasma6.enable = true;

  # Power Management
  services.upower = {
    enable = true;
    criticalPowerAction = "PowerOff";

    usePercentageForPolicy = true;
    percentageCritical = 3;
    percentageLow = 10;
  };
  services.tlp.enable = true;
  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

    CPU_MIN_PERF_ON_AC = 0;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_MIN_PERF_ON_BAT = 0;
    CPU_MAX_PERF_ON_BAT = 30;

    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "low-power";

    USB_AUTOSUSPEND = 0;
  };
  services.power-profiles-daemon.enable = false;
  # powerManagement.enable = true;
  # powerManagement.powertop.enable = true;
  services.logind.lidSwitch = "suspend";

  # Printing
  services.printing.drivers = with pkgs; [ epfl-cups-drivers ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
  # Keyboard
  services.input-remapper.enable = true;
  services.input-remapper.serviceWantedBy = [ "multi-user.target" ];
  hardware.uinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  common.linux.username = "nki";

  # Networking
  common.linux.networking = {
    hostname = "nki-yoga-g8";
    networks."10-wired".match = "enp*";
    networks."20-wireless".match = "wlan*";
    dnsServers = [ "127.0.0.1" ];
  };
  nki.services.edns.enable = true;
  nki.services.edns.ipv6 = true;

  # Backup home
  services.btrbk.extraPackages = with pkgs; [ sudo ];
  services.btrbk.instances.home = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve = "24h 30d 6m 1y";
      snapshot_preserve_min = "7d";
      volume."/" = {
        subvolume.home.snapshot_name = ".backups-home";
      };
    };
  };

  # Enable fingerprint auth for some stuff
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.swaylock.fprintAuth = true;
  security.pam.services.login.fprintAuth = true;

  # Secrets
  # sops.defaultSopsFile = ./secrets.yaml;
  # sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  ## tinc
  # sops.secrets."tinc/ed25519-private-key" = { };
  # services.my-tinc = {
  #   enable = true;
  #   hostName = "macbooknix";
  #   ed25519PrivateKey = config.sops.secrets."tinc/ed25519-private-key".path;
  #   bindPort = 6565;
  # };

  services.dbus.packages = with pkgs; [ gcr ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}

