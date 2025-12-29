{
  description = "nki's systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    deploy-rs.url = "github:Serokell/deploy-rs";

    # --- Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Build tools
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arion.url = "github:hercules-ci/arion/v0.2.2.0";

    # ---
    # Imported apps
    youmubot.url = "github:natsukagami/youmubot";
    mpd-mpris = {
      url = "github:natsukagami/mpd-mpris";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dtth-phanpy.url = "git+ssh://gitea@git.dtth.ch/nki-dtth/phanpy?ref=dtth-fork";
    conduit.url = "gitlab:famedly/conduit/v0.10.10";
    nix-gaming.url = "github:fufexan/nix-gaming";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    niri-stable.url = "github:YaLTeR/niri/v25.11";
    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.niri-stable.follows = "niri-stable";

    # --- Sources
    kakoune.url = "github:mawww/kakoune";
    kakoune.flake = false;
    kak-lsp.url = "github:kakoune-lsp/kakoune-lsp/v18.2.0";
    kak-lsp.flake = false;
    nixos-m1.url = "github:tpwrules/nixos-apple-silicon";
    nixos-m1.inputs.nixpkgs.follows = "nixpkgs";

    # ---
    # DEPLOYMENT ONLY! secrets
    secrets.url = "git+ssh://git@github.com/natsukagami/nix-deploy-secrets";
  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      deploy-rs,
      sops-nix,
      ...
    }@inputs:
    let
      overlays = import ./overlay.nix inputs;
      lib = nixpkgs.lib;

      applyOverlays =
        { ... }:
        {
          nixpkgs.overlays = lib.mkAfter overlays;
        };

      nixpkgsAsRegistry_ =
        stable:
        { lib, ... }:
        {
          imports = [ applyOverlays ];
          nix.registry.current-system.flake = self;
          nix.registry.nixpkgs-unstable.flake = nixpkgs-unstable;
          nixpkgs.config.allowUnfree = true;
          nix.nixPath = lib.mkDefault [
            "nixpkgs-unstable=${nixpkgs-unstable}"
          ];
        };

      osuStable =
        { pkgs, ... }:
        {
          nix.settings = {
            substituters = [ "https://nix-gaming.cachix.org" ];
            trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
          };
          environment.systemPackages = [ inputs.nix-gaming.packages.${pkgs.hostPlatform.system}.osu-stable ];
          programs.gamemode = {
            enable = true;
            enableRenice = true;
            settings = {
              general = {
                renice = 10;
              };

              custom = {
                start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
                end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
              };
            };
          };
        };

      # Common Nix modules
      common-nix =
        stable:
        { ... }:
        {
          imports = [
            (nixpkgsAsRegistry_ stable)
            ./common.nix
            sops-nix.nixosModules.sops
          ];
        };
      common-nixos =
        stable:
        { ... }:
        {
          imports = [
            ./modules/my-tinc
            ./modules/common/linux
            (common-nix stable)
            inputs.secrets.nixosModules.common
            inputs.nix-gaming.nixosModules.pipewireLowLatency
            inputs.niri.nixosModules.niri
          ];
        };

      mkPersonalSystem =
        nixpkgs-module: system:
        {
          configuration,
          homeManagerUsers ? { },
          extraModules ? [ ],
          includeCommonModules ? true,
        }:
        let
          home-manager-module =
            if nixpkgs-module == inputs.nixpkgs then
              inputs.home-manager
            else if nixpkgs-module == inputs.nixpkgs-unstable then
              inputs.home-manager-unstable
            else
              builtins.abort "Unknown nixpkgs module, use `nixpkgs` or `nixpkgs-unstable`";
        in
        nixpkgs-module.lib.nixosSystem {
          inherit system;
          modules =
            (
              if includeCommonModules then
                [
                  (common-nixos nixpkgs-module)
                ]
              else
                [ ]
            )
            ++ [
              configuration
              # Home Manager
              home-manager-module.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users = homeManagerUsers;
              }
            ]
            ++ extraModules;
        };

      kakoune-unwrapped-from-pkgs =
        pkgs:
        pkgs.kakoune-unwrapped.overrideAttrs (attrs: {
          version = "r${builtins.substring 0 6 inputs.kakoune.rev}";
          src = inputs.kakoune;
          patches = [
            # patches in the original package was already applied
          ];
        });
      nki-kakoune-from-pkgs =
        pkgs:
        pkgs.callPackage ./packages/common/nki-kakoune {
          kakoune-unwrapped = kakoune-unwrapped-from-pkgs pkgs;
        };

    in
    {
      overlays = {
        default = lib.composeManyExtensions overlays;
        kakoune = final: prev: {
          kakoune-unwrapped = kakoune-unwrapped-from-pkgs prev;
          nki-kakoune = final.callPackage ./packages/common/nki-kakoune { };
        };
      };

      packages.x86_64-linux.deploy-rs = deploy-rs.packages.x86_64-linux.default;
      apps.x86_64-linux.deploy-rs = deploy-rs.apps.x86_64-linux.default;

      packages.x86_64-linux.openconnect-epfl =
        (import nixpkgs-unstable { system = "x86_64-linux"; }).callPackage
          ./package/common/openconnect-epfl.nix
          { };

      packages.x86_64-linux.nki-kakoune = nki-kakoune-from-pkgs (
        import nixpkgs-unstable { system = "x86_64-linux"; }
      );
      packages.aarch64-linux.nki-kakoune = nki-kakoune-from-pkgs (
        import nixpkgs-unstable { system = "aarch64-linux"; }
      );
      packages.aarch64-darwin.nki-kakoune = nki-kakoune-from-pkgs (
        import nixpkgs-unstable { system = "aarch64-darwin"; }
      );

      # MacBook configuration: nix-darwin + home-manager
      darwinConfigurations."nki-macbook" = darwin.lib.darwinSystem rec {
        system = "aarch64-darwin";
        modules = [
          (common-nix nixpkgs-unstable)
          ./darwin/configuration.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/macbook-home.nix;
          }
        ];
      };

      # Home configuration
      nixosConfigurations."kagamiPC" = mkPersonalSystem nixpkgs-unstable "x86_64-linux" {
        configuration = ./nki-home/configuration.nix;
        homeManagerUsers.nki = import ./home/kagami-pc-home.nix;
        extraModules = [ osuStable ];
      };
      # yoga g8 configuration
      nixosConfigurations."nki-yoga-g8" = mkPersonalSystem nixpkgs "x86_64-linux" {
        configuration = ./nki-yoga-g8/configuration.nix;
        homeManagerUsers.nki = import ./home/nki-x1c1.nix;
        extraModules = [
          inputs.lanzaboote.nixosModules.lanzaboote
          (
            { ... }:
            {
              # Sets up secure boot
              boot.loader.systemd-boot.enable = lib.mkForce false;
              boot.lanzaboote = {
                enable = true;
                pkiBundle = "/var/lib/sbctl";
              };
            }
          )
        ];
      };
      # framework configuration
      nixosConfigurations."nki-framework" = mkPersonalSystem nixpkgs-unstable "x86_64-linux" {
        configuration = ./nki-framework/configuration.nix;
        homeManagerUsers.nki = import ./home/nki-framework.nix;
        extraModules = [
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.nixos-hardware.nixosModules.framework-13-7040-amd
          (
            { ... }:
            {
              # Sets up secure boot
              # boot.loader.systemd-boot.enable = lib.mkForce false;
              # boot.lanzaboote = {
              #   enable = true;
              #   pkiBundle = "/etc/secureboot";
              # };
            }
          )
        ];
      };
      # macbook nixos
      nixosConfigurations."kagami-air-m1" = mkPersonalSystem nixpkgs "aarch64-linux" {
        configuration = ./kagami-air-m1/configuration.nix;
        homeManagerUsers.nki = import ./home/macbook-nixos.nix;
        extraModules = [ inputs.nixos-m1.nixosModules.apple-silicon-support ];
      };

      # DigitalOcean node
      nixosConfigurations."nki-personal-do" = mkPersonalSystem nixpkgs "x86_64-linux" {
        configuration = ./nki-personal-do/configuration.nix;
        extraModules = [
          inputs.arion.nixosModules.arion
          inputs.youmubot.nixosModules.default
          inputs.secrets.nixosModules.nki-personal-do
        ];
      };
      deploy.nodes."nki-personal-do" = {
        hostname = "nki.personal";
        sshUser = "root";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."nki-personal-do";
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    }
    // (inputs.flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    }));
}
