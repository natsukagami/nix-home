rule = {
  matches = {
    {
      { "node.name", "matches", "alsa_output.usb-Grace_Design_SDAC-00.*" },
    },
  },
  apply_properties = {
    ["audio.format"] = "S24_3LE",
    ["audio.rate"] = 44100,
    ["api.alsa.period-size"] = 2,
    ["api.alsa.headroom"] = 0,
    ["api.alsa.disable-batch"] = true
  },
}

table.insert(alsa_monitor.rules, rule)
