{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.programs.my-sway;

  # Set up an ibus script
  ibusNext = (
    let
      input-methods = [ "xkb:us::eng" "mozc-jp" "Bamboo" ];
      next = m:
        let
          nextRec = l:
            if (length l == 1)
            then head input-methods
            else if (m == head l)
            then (head (tail l))
            else nextRec (tail l);
        in
        nextRec input-methods;
      inputCase = m: ''
        if test $current = "${m}"
          ${pkgs.libnotify}/bin/notify-send \
            -a ibus \
            -u low \
            -t 3000 \
            "${next m}" \
            "Input engine changed"
          ${pkgs.ibus}/bin/ibus engine ${next m}
        end
      '';
    in
    pkgs.writeScriptBin "ibus-next-engine" ''
      #! ${pkgs.fish}/bin/fish

      set current (${pkgs.ibus}/bin/ibus engine)

      ${strings.concatMapStrings inputCase input-methods}
    ''
  );

in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway.config.keybindings = mkOptionDefault {
      "${config.wayland.windowManager.sway.config.modifier}+z" = "exec ${ibusNext}/bin/ibus-next-engine";
    };
  };
}

