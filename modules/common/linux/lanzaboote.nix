{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.common.linux.secureBoot;
in
{
  options.common.linux = {
    secureBoot = {
      enable = lib.mkEnableOption "secure boot configuration";
      enableMeasuredBoot = lib.mkEnableOption "measured boot configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Sets up secure boot

    # Lanzaboote currently replaces the systemd-boot module.
    # This setting is usually set to true in configuration.nix
    # generated at installation time. So we force it to false
    # for now.
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      measuredBoot = {
        enable = cfg.enableMeasuredBoot;
        # See https://uapi-group.org/specifications/specs/linux_tpm_pcr_registry/
        pcrs = [
          0 # system firmware
          1 # basic hardware
          4 # boot loader
          7 # secure boot state
        ];
      };
      configurationLimit = 8;
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "systemd-cryptenroll-tpm" ''
        systemd-cryptenroll \
          --wipe-slot=tpm2 \
          --tpm2-device=auto \
          --tpm2-with-pin=true \
          --tpm2-pcrlock=/var/lib/systemd/pcrlock.json \
            "$@"
      '')
    ];
  };
}
