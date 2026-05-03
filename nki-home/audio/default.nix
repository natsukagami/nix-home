{
  ...
}:
{
  services.pipewire.lowLatency = {
    # enable this module
    enable = true;
    # defaults (no need to be set unless modified)
    quantum = 32;
    rate = 96000;
  };
  services.pipewire.wireplumber.extraConfig = {
    # "log-level-debug" = {
    #   "context.properties" = {
    #     # Output Debug log messages as opposed to only the default level (Notice)
    #     "log.level" = "D";
    #   };
    # };
    "51-sdac" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "~alsa_output.usb-Grace_Design_SDAC-00.*";
            }
          ];
          actions = {
            update-props = {
              "audio.format" = "S24_3LE";
              "audio.rate" = 0;
              "audio.allowed-rates" = "44100,48000,88200,96000";
              "node.max-latency" = 0;
              "api.alsa.period-size" = 2;
              "api.alsa.headroom" = 0;
              # "api.alsa.disable-batch" = true;
            };
          };
        }
      ];
    };
  };
}
