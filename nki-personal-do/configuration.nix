{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    
  ];

  boot.cleanTmpDir = true;
  networking.hostName = "nki-personal";
  networking.firewall.allowPing = true;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLr1Q+PJuDYJtBAVMSU0U2kZi4V0Z7dE+dpRxa4aEDupSlcPCwSEtcpNME1up7z0yxjcIHHkBYq0RobIaLqwEmntnZzz37jg/iiHwyZsN93jZljId1X0uykcMem4ljiqgmRg3Fs8RKj2+N1ovpIZVDOWINLJJDVJntNvwW/anSCtx27FATVdroHoiyXCwVknG6p3bHU5Nd3idRMn45kZ7Qf1J50XUhtu3ehIWI2/5nYIbi8WDnzY5vcRZEHROyTk2pv/m9rRkCTaGnUdZsv3wfxeeT3223k0mUfRfCsiPtNDGwXn66HcG2cmhrBIeDoZQe4XNkzspaaJ2+SGQfO8Zf natsukagami@gmail.com" 
  ];

  environment.systemPackages = with pkgs; [
  ];

  services.do-agent.enable = true;

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
}