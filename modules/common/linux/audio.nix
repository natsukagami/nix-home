{ ... }:
{
  services.pipewire.wireplumber.extraConfig = {
    "51-xm4-codec" = {
      "monitor.bluez.rules" = [
        {
          matches = [
            {
              # Match any bluetooth device with ids equal to that of a WH-1000XM4
              "device.name" = "~bluez_card.*";
              "device.product.id" = "0x0d58";
              "device.vendor.id" = "usb:054c";
            }
          ];
          actions = {
            update-props = {
              "bluez5.codec" = "sbc_xq";
            };
          };
        }
      ];
    };
  };
}
