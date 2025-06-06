{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.programs.my-broot;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.my-broot = {
    enable = mkEnableOption "Enable broot with my own extra configuration";
  };

  config = mkIf cfg.enable {
    programs.broot = {
      enable = true;
      settings.modal = true;

      settings.verbs = [
        {
          invocation = "edit";
          key = "enter";
          external = "$EDITOR {file}";
          leave_broot = false;
          apply_to = "file";
        }
      ];

      settings.skin = {
        default = "none none";
        tree = "gray(7) None / gray(18) None";
        file = "gray(3) None / gray(8) None";
        directory = "ansi(25) None Bold / ansi(25) None";
        exe = "ansi(130) None";
        link = "Magenta None";
        pruning = "gray(12) None Italic";
        perm__ = "gray(5) None";
        perm_r = "ansi(94) None";
        perm_w = "ansi(132) None";
        perm_x = "ansi(65) None";
        owner = "ansi(138) None";
        group = "ansi(131) None";
        dates = "ansi(66) None";
        sparse = "ansi(214) None";
        git_branch = "ansi(229) None";
        git_insertions = "ansi(28) None";
        git_deletions = "ansi(160) None";
        git_status_current = "gray(5) None";
        git_status_modified = "ansi(28) None";
        git_status_new = "ansi(94) None Bold";
        git_status_ignored = "gray(17) None";
        git_status_conflicted = "ansi(88) None";
        git_status_other = "ansi(88) None";
        selected_line = "None gray(19) / None gray(21)";
        char_match = "ansi(22) None";
        file_error = "Red None";
        flag_label = "gray(9) None";
        flag_value = "ansi(166) None Bold";
        input = "gray(1) None / gray(4) gray(20)";
        status_error = "gray(22) ansi(124)";
        status_normal = "gray(2) gray(20)";
        status_job = "ansi(220) gray(5)";
        status_italic = "ansi(166) gray(20)";
        status_bold = "ansi(166) gray(20)";
        status_code = "ansi(17) gray(20)";
        status_ellipsis = "gray(19) gray(15)";
        purpose_normal = "gray(20) gray(2)";
        purpose_italic = "ansi(178) gray(2)";
        purpose_bold = "ansi(178) gray(2) Bold";
        purpose_ellipsis = "gray(20) gray(2)";
        scrollbar_track = "gray(20) none";
        scrollbar_thumb = "ansi(238) none";
        help_paragraph = "gray(2) none";
        help_bold = "ansi(202) none bold";
        help_italic = "ansi(202) none italic";
        help_code = "gray(5) gray(22)";
        help_headers = "ansi(202) none";
        help_table_border = "ansi(239) None";
        preview_title = "gray(3) None / gray(5) None";
        preview = "gray(5) gray(23) / gray(7) gray(23)";
        preview_line_number = "gray(6) gray(20)";
        preview_match = "None ansi(29) Underlined";
        hex_null = "gray(15) None";
        hex_ascii_graphic = "gray(2) None";
        hex_ascii_whitespace = "ansi(143) None";
        hex_ascii_other = "ansi(215) None";
        hex_non_ascii = "ansi(167) None";
        staging_area_title = "gray(8) None / gray(13) None";
        mode_command_mark = "gray(15) ansi(204) Bold";
      };
    };

    # Add an extra syntax_color config
    xdg.configFile."broot/conf.toml".source = mkOverride 1 (
      tomlFormat.generate "broot-config" (
        with config.programs.broot;
        {
          inherit (settings) verbs modal skin;
          syntax_theme = "base16-ocean.light";
        }
      )
    );
  };
}
