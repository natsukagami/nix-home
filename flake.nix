{
  description = "nki's systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    deploy-rs.url = "github:Serokell/deploy-rs";
    nur.url = "github:nix-community/NUR";

    # --- Secure boot
    lanzaboote = {
      url = github:nix-community/lanzaboote/v0.3.0;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Build tools
    flake-utils.url = github:numtide/flake-utils;
    crane.url = github:ipetkov/crane;
    arion.url = github:hercules-ci/arion;
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ---
    # Imported apps
    youmubot.url = "github:natsukagami/youmubot";
    swayfx = {
      url = github:WillPower3309/swayfx;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mpd-mpris = {
      url = github:natsukagami/mpd-mpris;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dtth-phanpy.url = "git+ssh://gitea@git.dtth.ch/nki/phanpy?branch=dtth-fork";
    conduit.url = "gitlab:famedly/conduit/v0.8.0";
    nix-gaming.url = github:fufexan/nix-gaming;

    # --- Sources
    kakoune.url = github:mawww/kakoune;
    kakoune.flake = false;
    kak-lsp.url = github:kakoune-lsp/kakoune-lsp;
    kak-lsp.flake = false;

    # ---
    # DEPLOYMENT ONLY! secrets
    secrets.url = "git+ssh://git@github.com/natsukagami/nix-deploy-secrets";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, deploy-rs, sops-nix, nur, ... }@inputs:
    let
      overlays = import ./overlay.nix inputs;
      lib = nixpkgs.lib;

      applyOverlays = { ... }: {
        nixpkgs.overlays = lib.mkBefore overlays;
      };

      nixpkgsAsRegistry_ = stable: { lib, ... }: {
        imports = [ applyOverlays ];
        nix.registry.current-system.flake = self;
        nix.registry.nixpkgs-unstable.flake = nixpkgs-unstable;
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = lib.mkDefault [
          "nixpkgs-unstable=${nixpkgs-unstable}"
        ];
      };

      osuStable = { pkgs, ... }: {
        nix.settings = {
          substituters = [ "https://nix-gaming.cachix.org" ];
          trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
        };
        environment.systemPackages = [ inputs.nix-gaming.packages.${pkgs.hostPlatform.system}.osu-stable ];
      };

      # Common Nix modules
      common-nix = stable: { ... }: {
        imports = [
          (nixpkgsAsRegistry_ stable)
          ./common.nix
          sops-nix.nixosModules.sops
          inputs.lix-module.nixosModules.default
        ];
      };
      common-nixos = stable: { ... }: {
        imports = [
          ./modules/my-tinc
          ./modules/common/linux
          (common-nix stable)
          inputs.secrets.nixosModules.common
          inputs.nix-gaming.nixosModules.pipewireLowLatency
        ];
      };

      mkPersonalSystem = nixpkgs-module: system: { configuration
                                                 , homeManagerUsers ? { }
                                                 , extraModules ? [ ]
                                                 , includeCommonModules ? true
                                                 ,
                                                 }:
        let
          home-manager-module =
            if nixpkgs-module == inputs.nixpkgs then inputs.home-manager
            else if nixpkgs-module == inputs.nixpkgs-unstable then inputs.home-manager-unstable
            else builtins.abort "Unknown nixpkgs module, use `nixpkgs` or `nixpkgs-unstable`";
        in
        nixpkgs-module.lib.nixosSystem {
          inherit system;
          modules =
            (if includeCommonModules then [
              (common-nixos nixpkgs-module)
            ] else [ ]) ++ [
              configuration
              # Home Manager
              home-manager-module.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users = homeManagerUsers;
              }
            ] ++ extraModules;
        };

    in
    {
      overlays.default = lib.composeManyExtensions overlays;

      packages.x86_64-linux.deploy-rs = deploy-rs.packages.x86_64-linux.default;
      apps.x86_64-linux.deploy-rs = deploy-rs.apps.x86_64-linux.default;

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
          ({ ... }: {
            # Sets up secure boot
            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.lanzaboote = {
              enable = true;
              pkiBundle = "/etc/secureboot";
            };
          })
        ];
      };
      # framework configuration
      nixosConfigurations."nki-framework" = mkPersonalSystem nixpkgs-unstable "x86_64-linux" {
        configuration = ./nki-framework/configuration.nix;
        homeManagerUsers.nki = import ./home/nki-framework.nix;
        extraModules = [
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.nixos-hardware.nixosModules.framework-13-7040-amd
          ({ ... }: {
            # Sets up secure boot
            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.lanzaboote = {
              enable = true;
              pkiBundle = "/etc/secureboot";
            };
          })
        ];
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
    } // (inputs.flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    }));
}

