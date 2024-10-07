{ writeTextDir, ... }:
let
  themes = [
    { name = "catppuccin-latte"; src = ./themes/catppuccin-latte.kak; }
  ];

  themeToColorscheme = { name, src }: writeTextDir "share/kak/colors/${name}.kak" (builtins.readFile src);
in
builtins.map themeToColorscheme themes
