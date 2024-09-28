{ writeScriptDir, ... }:
let
  themes = [
    { name = "catppuccin-latte"; src = ./themes/catppucin-latte.kak; }
  ];

  themeToColorscheme = name: src: writeScriptDir "share/kak/colors/${name}.kak" (builtins.readFile src);
in
builtins.map themeToColorscheme themes
