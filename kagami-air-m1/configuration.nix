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
      ../modules/services/swaylock.nix
      # Encrypted DNS
      ../modules/services/edns
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Asahi kernel configuration
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.asahi.use4KPages = true;

  networking.hostName = "kagami-air-m1"; # Define your hostname.

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.wireless.iwd.enable = true;
  networking.interfaces.wlan0.useDHCP = true;

  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.inputMethod.enabled = "ibus";
  i18n.inputMethod.ibus.engines = (with pkgs.ibus-engines; [ bamboo mozc libpinyin ]);
  console = {
    # font = "ter-v32n";
    keyMap = "jp106";
    # useXkbConfig = true; # use xkbOptions in tty.
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.displayManager.sddm.enableHidpi = true;
  # services.xserver.desktopManager.plasma5.enable = true;
  services.gnome.gnome-keyring.enable = true;

  services.udev.packages = with pkgs; [ libfido2 ];

  # Configure keymap in X11
  # services.xserver.layout = "jp106";
  # services.xserver.xkbOptions = {
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  services.pipewire = {
    enable = true;
    # alsa is optional
    alsa.enable = true;
    alsa.support32Bit = true;

    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
  # Keyboard
  services.input-remapper.enable = true;
  services.input-remapper.package = pkgs.input-remapper.overridePythonAttrs {
    src = pkgs.fetchFromGitHub {
      owner = "sezanzeb";
      repo = "input-remapper";
      rev = "b047843545c85543e43f36ecc3b51e343c29c872";
      sha256 = "sha256-um7fsoEndFLd8JzvCiSSIDpFFmBwtS9GmRag310iKfk=";
    };
  };
  services.input-remapper.serviceWantedBy = [ "multi-user.target" ];
  hardware.uinput.enable = true;
  hardware.opengl.enable = true;
  services.swaylock.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nki = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      # kakoune
      # thunderbird
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    kakoune # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget

    libfido2

    ## Security stuff
    libsForQt5.qtkeychain

    ## Wayland
    qt5.qtwayland

    ## Drivers...?
    libimobiledevice
  ];

  services.usbmuxd.enable = true;

  # Enable sway on login.
  environment.loginShellInit = ''
    if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec sway
    fi
  '';

  # Environment variables
  environment.variables = {
    # Input method overrides
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    "XMODIFIERS=@im" = "ibus";

    # Basic editor setup
    EDITOR = "kak";
    VISUAL = "kak";
  };

  services.resolved.enable = true;
  services.resolved.domains = [ "127.0.0.1" ];
  services.resolved.fallbackDns = [ "127.0.0.1" ];
  nki.services.edns.enable = true;
  nki.services.edns.ipv6 = true;
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  ## Bluetooth
  #
  hardware.bluetooth.enable = true;


  # PAM
  security.pam.services.sddm.enableKwallet = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.login.enableKwallet = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs.kdeconnect.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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
    powerDownCommands = ''
      /run/current-system/sw/bin/rmmod brcmfmac # Disable wifi
      /run/current-system/sw/bin/rmmod hci_bcm4377 # Disable bluetooth
    '';
    resumeCommands = ''
      /run/current-system/sw/bin/modprobe brcmfmac # Enable wifi
      /run/current-system/sw/bin/modprobe hci_bcm4377 # Enable bluetooth
      /run/current-system/sw/bin/systemctl restart iwd
      /run/current-system/sw/bin/systemctl restart bluetooth
    '';
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

