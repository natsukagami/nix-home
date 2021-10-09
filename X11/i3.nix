{ pkgs, config, lib, ... } :

let
    mod = "Mod4";
    workspaces = [
        "1: web"
        "2: chat"
        "3: code"
        "4: music"
        "5: extra"
        "6: 6"
        "7: 7"
        "8: 8"
        "9: 9"
        "10: 10"
    ];
    wsAttrs = builtins.listToAttrs (
        map
            (i: { name = toString (remainder i 10); value = builtins.elemAt workspaces (i - 1); })
            (range 1 11)
    );
    remainder = x: y: x - (builtins.div x y) * y;
    range = from: to:
        let
            f = cur: if cur == to then [] else [cur] ++ f (cur + 1);
        in f from;
in
{
    ## i3 window manager
    xsession.windowManager.i3 = {
        enable = true;
        config.assigns = {
            "${wsAttrs."1"}" = [ { class = "^Firefox$"; } ];
            "${wsAttrs."2"}" = [ { class = "^Discord$"; } ];
        };
        config.bars = [ {
            command = "${pkgs.i3-gaps}/bin/i3bar -t";
            statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-default.toml";
            position = "top";
            colors = {
                background = "#00000080";
                statusline = "#ffffff";
                separator = "#666666";

                focusedWorkspace = { background = "#4c7899"; border = "#285577"; text = "#ffffff"; };
                activeWorkspace = { background = "#333333"; border = "#5f676a"; text = "#ffffff"; };
                inactiveWorkspace = { background = "#333333"; border = "#222222"; text = "#888888"; };
                urgentWorkspace = { background = "#2f343a"; border = "#900000"; text = "#ffffff"; };
                bindingMode = { background = "#2f343a"; border = "#900000"; text = "#ffffff"; };
            };
        } ];
        config.fonts = { names = [ "FantasqueSansMono Nerd Font Mono" "monospace" ]; size = 11.0; };
        config.gaps.outer = 5;
        config.gaps.inner = 5;
        config.gaps.smartGaps = true;
        config.modifier = mod;
        config.terminal = "alacritty";
        config.window.titlebar = false;

        # Keybindings
        config.keybindings = lib.mkOptionDefault ({
            ## vim-style movements
            "${mod}+h" = "focus left";
            "${mod}+j" = "focus down";
            "${mod}+k" = "focus up";
            "${mod}+l" = "focus right";
            "${mod}+Shift+h" = "move left";
            "${mod}+Shift+j" = "move down";
            "${mod}+Shift+k" = "move up";
            "${mod}+Shift+l" = "move right";
            ## Splits
            "${mod}+v" = "split v";
            "${mod}+Shift+v" = "split h";
            ## Run
            "${mod}+r" = "exec ${pkgs.dmenu}/bin/dmenu_run";
            "${mod}+d" = "exec i3-dmenu-desktop --dmenu='${pkgs.dmenu}/bin/dmenu -i'";
        } // (
            builtins.listToAttrs (lib.flatten (map (key: [
                {
                    name = "${mod}+${key}";
                    value = "workspace ${builtins.getAttr key wsAttrs}";
                }
                {
                    name = "${mod}+Shift+${key}";
                    value = "move to workspace ${builtins.getAttr key wsAttrs}";
                }
            ]) (builtins.attrNames wsAttrs))
        )));
    };


    # i3status
    programs.i3status-rust.enable = true;
    programs.i3status-rust.bars.default = {
        icons = "material-nf";
        theme = "native";
        settings = {
            icons_format = " <span font_family='FantasqueSansMono Nerd Font'>{icon}</span> ";
        };
        blocks = [
            {
                block = "bluetooth";
                mac = "5C:52:30:D8:E2:9D";
                format = "Airpods Pro {percentage}";
                format_unavailable = "Airpods Pro XX";
            }
            {
                block = "cpu";
                format = "{utilization}";
            }
            {
                block = "hueshift";
            }
            {
                block = "memory";
            }
            {
                block = "net";
            }
            {
                block = "sound";
            }
            {
                block = "time";
            }
        ];
    };
}
