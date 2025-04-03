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
        if set -q kak_session
          echo "Another kakoune session ($kak_session) is currently running. Do `kill-kak-session` to stop it." >&2
          return 1
        end

        if test (count $argv) -ge 1
          set -gx kak_session $argv[1]
        else
          set -gx kak_session "kak-"(random)
        end

        # Start a new kakoune session
        kak -s $kak_session -d &
        echo "New kakoune session started (pid = $last_pid, session name = $kak_session)."

        # Rebind $VISUAL, $EDITOR and e command
        set -gx VISUAL "kak -c $kak_session"
        set -gx EDITOR "kak -c $kak_session"
        alias e="kak -c $kak_session"
      '';

      kill-kak-session = ''
        if not set -q kak_session
          echo "No kakoune session found on this terminal instance." >&2
          return 1
        end

        echo kill | kak -p $kak_session
        set -eg kak_session

        # Rebind $VISUAL, $EDITOR and e command
        set -gx VISUAL "kak"
        set -gx EDITOR "kak"
        alias e="kak"
      '';
    };
    programs.fish.tide = {
      items.kakoune = ''
        if set -q kak_session
          set -U tide_kakoune_color FFA500
          set -U tide_kakoune_bg_color normal
          _tide_print_item kakoune " " "e[$kak_session]"
        end
      '';
      rightItems = mkAfter [ "kakoune" ];
    };
  };
}
