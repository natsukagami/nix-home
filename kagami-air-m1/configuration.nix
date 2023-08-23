# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Fonts
      ../modules/personal/fonts
      # Encrypted DNS
      ../modules/services/edns
    ];

  # I'm away
  time.timeZone = lib.mkForce "Asia/Ho_Chi_Minh";
  services.xserver.desktopManager.plasma5.enable = true;


  # Asahi kernel configuration
  hardware.asahi = {
    peripheralFirmwareDirectory = ./firmware;
    use4KPages = false;
    withRust = true;
    addEdgeKernelConfig = true;
    useExperimentalGPUDriver = true;
    experimentalGPUInstallMode = "overlay";
  };

  # Power Management
  services.upower = {
    enable = true;
    criticalPowerAction = "PowerOff";

    usePercentageForPolicy = true;
    percentageCritical = 3;
    percentageLow = 10;
  };
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

  # Enable sway on login.
  environment.loginShellInit = ''
    if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec sway
    fi
  '';

  # Networking
  common.linux.networking = {
    hostname = "kagami-air-m1";
    networks."10-wired".match = "enp*";
    networks."20-wireless".match = "wlan*";
    dnsServers = [ "127.0.0.1" ];
  };
  nki.services.edns.enable = true;
  nki.services.edns.ipv6 = true;

  # Secrets
  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  ## tinc
  sops.secrets."tinc/ed25519-private-key" = { };
  services.my-tinc = {
    enable = true;
    hostName = "macbooknix";
    ed25519PrivateKey = config.sops.secrets."tinc/ed25519-private-key".path;
    bindPort = 6565;
  };

  services.dbus.packages = with pkgs; [ gcr ];

  # Power Management
  powerManagement = {
    enable = true;
    # powerDownCommands = ''
    #   /run/current-system/sw/bin/rmmod brcmfmac # Disable wifi
    #   /run/current-system/sw/bin/rmmod hci_bcm4377 # Disable bluetooth
    # '';
    # resumeCommands = ''
    #   /run/current-system/sw/bin/modprobe brcmfmac # Enable wifi
    #   /run/current-system/sw/bin/modprobe hci_bcm4377 # Enable bluetooth
    #   /run/current-system/sw/bin/systemctl restart iwd
    #   /run/current-system/sw/bin/systemctl restart bluetooth
    # '';
  };

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

