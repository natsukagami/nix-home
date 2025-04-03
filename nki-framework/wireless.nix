{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [ iw ];
  # Disable power_save on boot
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "udev_disable_wifi_power_save";
      destination = "/etc/udev/rules.d/10-wifi-power_save.rules";
      text = ''
        ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${lib.getExe pkgs.iw} dev $name set power_save off"
      '';
    })
  ];
}
