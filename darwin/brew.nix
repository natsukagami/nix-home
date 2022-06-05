{ pkgs, config, lib, ... }:

with lib;
{
  homebrew.enable = true;
  homebrew.brewPrefix =
    if pkgs.system == "aarch64-darwin" then "/opt/homebrew/bin"
    else "/usr/local/bin";
  homebrew.cleanup = "zap";

  # All needed taps
  homebrew.taps = [
    "homebrew/bundle"
    "homebrew/cask"
    "homebrew/core"
  ];

  homebrew.brews = [
    # Base libraries
    "coreutils"

    # Compilers and Language Interpreters
    "elm"
    "llvm"
    "luajit-openresty"
    "node"
    "perl"
    "ruby@2.7"

    # CLI tools
    "pinentry-mac" # UI for Pin Entry on gpg Mac

    # U2F
    "pam-u2f"
  ] ++ (optionals (pkgs.system == "aarch64-darwin") [
    # Because python on Nix is a bit abababa
    "python@3.9"
    "scipy"
  ]);

  homebrew.casks = [
    "anki"
    "blackhole-2ch"
    "eloston-chromium"
    "finicky"
    "inkscape"
    "yt-music"

    # CLI, but doesn't yet work on Nix
    # "sage"
  ];

  homebrew.masApps = {
    # Safari Extensions
    "Keepa - Price Tracker" = 1533805339;
    "Vimari" = 1480933944;
    "Bitwarden" = 1352778147;
    "Save to Pocket" = 1477385213;
    "AdGuard for Safari" = 1440147259;
    "Refined GitHub" = 1519867270;

    # Productivity
    "GoodNotes" = 1444383602;
    "Amphetamine" = 937984704; # Turns off auto display dimming and sleep for some time
    "Session Pal" = 1515213004;
    "Flow" = 1423210932;
    # "Taskheat" = 1431995750; # Always shown outdated!
    "Hidden Bar" = 1452453066;

    # Development
    "Developer" = 640199958;
    # "Xcode" = 497799835;

    # Chat
    "Messenger" = 1480068668;
    "LINE" = 539883307;
    "Slack" = 803453959;

    # Office
    "Keynote" = 409183694;
    "Microsoft Excel" = 462058435;
    "The Unarchiver" = 425424353;
    "Numbers" = 409203825;
    "Pages" = 409201541;
    ## Multimedia
    "DaVinci Resolve" = 571213070;
    "GarageBand" = 682658836;
    "iMovie" = 408981434;
  };
}
