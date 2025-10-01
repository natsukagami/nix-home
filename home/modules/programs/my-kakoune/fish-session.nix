{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.programs.my-kakoune;
in
{
  options.programs.my-kakoune.enable-fish-session = mkEnableOption "Enable fish integration script";
  config = mkIf cfg.enable-fish-session {
    programs.fish.functions = {
      kak-session = ''
        if set -q fish_kak_session
          echo "Another kakoune session ($fish_kak_session) is currently running. Do `kill-kak-session` to stop it." >&2
          return 1
        end

        if test (count $argv) -ge 1
          set -gx fish_kak_session $argv[1]
        else
          set -gx fish_kak_session "kak-"(random)
        end

        # Start a new kakoune session
        kak -s $fish_kak_session -d &
        echo "New kakoune session started (pid = $last_pid, session name = $fish_kak_session)."

        # Rebind $VISUAL, $EDITOR and e command
        set -gx VISUAL kak -c $fish_kak_session
        set -gx EDITOR kak -c $fish_kak_session
      '';

      kill-kak-session = ''
        if not set -q fish_kak_session
          echo "No kakoune session found on this terminal instance." >&2
          return 1
        end

        echo kill | kak -p $fish_kak_session
        set -eg fish_kak_session

        # Rebind $VISUAL, $EDITOR and e command
        set -gx VISUAL "kak"
        set -gx EDITOR "kak"
      '';
    };
    programs.fish.tide = {
      items.kakoune = ''
        if set -q fish_kak_session
          set -U tide_kakoune_color FFA500
          set -U tide_kakoune_bg_color normal
          _tide_print_item kakoune " " "e[$fish_kak_session]"
        end
      '';
      rightItems = mkAfter [ "kakoune" ];
    };
  };
}
