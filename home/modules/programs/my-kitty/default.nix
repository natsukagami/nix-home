{ pkgs, config, lib, ... }:

let
  cfg = config.nki.programs.kitty;

  # iosevka = pkgs.iosevka.override {
  #   privateBuildPlan = ''
  #     [buildPlans.iosevka-kagami]
  #     family = "Iosevka Kagami"
  #     spacing = "normal"
  #     serifs = "sans"
  #     no-cv-ss = true

  #       [buildPlans.iosevka-kagami.variants]
  #       inherits = "ss06"

  #         [buildPlans.iosevka-kagami.variants.design]
  #         k = "cursive-serifless"

  #       [buildPlans.iosevka-kagami.ligations]
  #       inherits = "haskell"
  #   '';
  #   set = "kagami";
  # };

  cmd = if pkgs.stdenv.isDarwin then "cmd" else "ctrl";
in
with lib;
{
  imports = [ ./darwin.nix ];

  options.nki.programs.kitty = {
    enable = mkEnableOption "Enable kitty";

    # font
    fontSize = mkOption {
      type = types.int;
      description = "Font size";
      default = 21;
    };

    background = mkOption
      {
        type = types.nullOr types.path;
        description = "Path to the background image. If not set, default to a 0.9 opacity";
        default = null;
      };
  };

  config.programs.kitty = mkIf cfg.enable {
    enable = true;

    font.package = pkgs.fantasque-sans-mono;
    font.name = "Fantasque Sans Mono";
    font.size = cfg.fontSize;

    theme = "Ayu Light";

    extraConfig =
      let
        background =
          if isNull cfg.background then ''
            background_opacity 1
            dynamic_background_opacity yes
          '' else ''
            background_image ${cfg.background}
            background_image_layout scaled
            background_tint 0.85
          '';
      in
      ''
        # Background color and transparency
        ${background}

        # Scrollback (128MBs)
        scrollback_pager_history_size 128

        # Disable Shell integration (leave it for Nix)
        shell_integration no-rc
      '';

    keybindings = { };
  };
}

