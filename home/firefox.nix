{ pkgs, config, lib, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland.override {
      cfg = {
        # Tridactyl native connector
        enableTridactylNative = true;
      };
    };
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      bitwarden
      grammarly
      https-everywhere
      multi-account-containers
      octotree
      reddit-enhancement-suite
      refined-github
      simple-tab-groups
      sponsorblock
      tridactyl
      ublock-origin
      web-scrobbler
    ];

    profiles.nki.id = 0;
    profiles.nki.isDefault = true;
    profiles.nki.settings = {
      "browser.search.region" = "CA";
    };
  };
}
