# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # secret management
      ./secrets
      # Fonts
      ../modules/personal/fonts
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
      plymouth.enable = true;
      loader.timeout = 60;
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
  };
  ## Encryption
  # Kernel modules needed for mounting USB VFAT devices in initrd stage
  boot.initrd.kernelModules = [ "usb_storage" ];
  boot.initrd.luks.devices = {
      root = {
          keyFile = "/dev/disk/by-id/usb-090c___B1608112001295-0:0";
          keyFileSize = 4096;
          fallbackToPassword = true;
          device = "/dev/disk/by-uuid/7c6e40a8-900b-4f85-9712-2b872caf1892";
          preLVM = true;
          allowDiscards = true;
      };
  };

  networking.hostName = "kagamiPC"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp8s0.useDHCP = true;
  networking.interfaces.wlp7s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.inputMethod.enabled = "ibus";
  i18n.inputMethod.ibus.engines = (with pkgs.ibus-engines; [bamboo mozc libpinyin]);
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
 
  # Configure keymap in X11
  services.xserver.layout = "jp";
  # services.xserver.xkbOptions = "";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
    package = pkgs.pulseaudioFull;
  };
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nki = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # Allow all packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    kakoune # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    fish
    firefox

    ## System monitoring tools
    busybox

    ## Security stuff
    qtkeychain

    ## Enable nix-flakes
    # (pkgs.writeShellScriptBin "nixFlakes" ''
    #   exec ${pkgs.nixUnstable}/bin/nix --experimental-features "nix-command flakes" "$@"
    # '')
  ];

  # Nix config
  nix.binaryCachePublicKeys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
  nix.binaryCaches = [ "https://hydra.iohk.io" ];

  
  # Terminal 
  programs.gnome-terminal.enable = true;

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

  # Enable Desktop Environment.
  services.xserver.displayManager = {
      lightdm.enable = true;
  };
  services.xserver.desktopManager.cinnamon.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:
  services.gnome.gnome-keyring.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 22 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  #

  ## Bluetooth
  #
  hardware.bluetooth.enable = true;

  # Peripherals
  hardware.opentabletdriver.enable = true;

  # VPN
  sops.secrets."windscribe/privateKey" = { mode = "0755"; };
  sops.secrets."windscribe/presharedKey" = { mode = "0755"; };
  networking.wg-quick.interfaces = {
      windscribe = {
          privateKeyFile = config.sops.secrets."windscribe/privateKey".path;
          address = [ "100.70.42.56/32" ];
          dns = [ "10.255.255.2" ];
          peers = [
              {
                  allowedIPs = [ "0.0.0.0/0" ];
                  endpoint = "yyz-197-wg.whiskergalaxy.com:443";
                  presharedKeyFile = config.sops.secrets."windscribe/presharedKey".path;
                  publicKey = "U5s7Yy/2fCqlaFcI96dFKupqEVCn+BYF04LRLD1zOhg=";
              }
          ];
      };
  };

  

  # PAM
  security.pam.services.lightdm.enableKwallet = true;
  security.pam.services.lightdm.enableGnomeKeyring = true;
  

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-21.05/";

  # tinc network
  sops.secrets."tinc/ed25519-private-key" = {};
  sops.secrets."tinc/rsa-private-key" = {};
  services.my-tinc = {
    enable = true;
    hostName = "home";
    rsaPrivateKey = config.sops.secrets."tinc/rsa-private-key".path;
    ed25519PrivateKey = config.sops.secrets."tinc/ed25519-private-key".path;
    bindPort = 6565;
  };

  # extra host for my personal server
  sops.secrets.hosts = {
      mode = "0755";
  };
  services.dnsmasq.enable = true;
  services.dnsmasq.extraConfig = ''
    addn-hosts=${config.sops.secrets.hosts.path}
  '';
}

