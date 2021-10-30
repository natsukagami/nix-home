{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "8.8.8.8"
 ];
    defaultGateway = "137.184.192.1";
    defaultGateway6 = "2604:a880:400:d0::1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="137.184.192.31"; prefixLength=20; }
{ address="10.10.0.5"; prefixLength=16; }
        ];
        ipv6.addresses = [
          { address="2604:a880:400:d0::1f75:4001"; prefixLength=64; }
{ address="fe80::3ceb:bbff:fe9c:96b3"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "137.184.192.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "2604:a880:400:d0::1"; prefixLength = 128; } ];
      };
      
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="3e:eb:bb:9c:96:b3", NAME="eth0"
    ATTR{address}=="12:b3:87:0f:87:f8", NAME="eth1"
  '';
}
