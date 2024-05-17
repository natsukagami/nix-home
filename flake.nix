{
  description = "nki's systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
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
    conduit = {
      url = gitlab:famedly/conduit/next;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    eza.url = github:eza-community/eza/v0.12.0;
    eza.inputs.nixpkgs.follows = "nixpkgs";
    nix-gaming.url = github:fufexan/nix-gaming/22586cc4910284c9c7306f19dcd63ac0adbcbcc9; # until we jump to 24.05

    # --- Sources
    kakoune.url = github:mawww/kakoune;
    kakoune.flake = false;
    kak-lsp.url = github:kakoune-lsp/kakoune-lsp;
    kak-lsp.flake = false;
    nixos-m1.url = github:tpwrules/nixos-apple-silicon;
    nixos-m1.inputs.nixpkgs.follows = "nixpkgs";

    # ---
    # DEPLOYMENT ONLY! secrets
    secrets.url = "git+ssh://git@github.com/natsukagami/nix-deploy-secrets";
  };

  outputs = { self, darwin, nixpkgs, nixpkgs-unstable, home-manager, deploy-rs, sops-nix, nur, ... }@inputs:
    let
      overlays = import ./overlay.nix inputs;
      lib = nixpkgs.lib;

      applyOverlays = { ... }: {
        nixpkgs.overlays = lib.mkBefore overlays;
      };

      nixpkgsAsRegistry_ = stable: { lib, ... }: {
        imports = [ applyOverlays ];
        nix.registry.current-system.flake = self;
        nix.registry.nixpkgs.flake = stable;
        nix.registry.nixpkgs-unstable.flake = nixpkgs-unstable;
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [
          "nixpkgs=${nixpkgs}"
          "nixpkgs-unstable=${nixpkgs-unstable}"
          "/nix/var/nix/profiles/per-user/root/channels"
        ];
        # Binary Cache for Haskell.nix  
        nix.settings.trusted-public-keys = [
          # "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        ];
        nix.settings.substituters = [
          # "https://cache.iog.io"
        ];
      };
      nixpkgsAsRegistry = nixpkgsAsRegistry_ nixpkgs;

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

    in
    {
      overlays.default = lib.composeManyExtensions overlays;

      packages.x86_64-linux.deploy-rs = deploy-rs.packages.x86_64-linux.default;
      apps.x86_64-linux.deploy-rs = deploy-rs.apps.x86_64-linux.default;

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
      nixosConfigurations."kagamiPC" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          (common-nixos nixpkgs)
          ./nki-home/configuration.nix
          osuStable
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = { ... }: {
              imports = [
                ./home/kagami-pc-home.nix
              ];
            };
          }
        ];
      };
      # yoga g8 configuration
      nixosConfigurations."nki-yoga-g8" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          (common-nixos nixpkgs)
          inputs.lanzaboote.nixosModules.lanzaboote
          ({ ... }: {
            # Sets up secure boot
            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.lanzaboote = {
              enable = true;
              pkiBundle = "/etc/secureboot";
            };
          })
          ./nki-yoga-g8/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/nki-x1c1.nix;
          }
        ];
      };
      # framework configuration
      nixosConfigurations."nki-framework" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          (common-nixos nixpkgs)
          inputs.lanzaboote.nixosModules.lanzaboote
          ({ ... }: {
            # Sets up secure boot
            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.lanzaboote = {
              enable = true;
              pkiBundle = "/etc/secureboot";
            };
          })
          ./nki-framework/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/nki-framework.nix;
          }
        ];
      };
      # macbook nixos
      nixosConfigurations."kagami-air-m1" = inputs.nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        modules = [
          (common-nixos inputs.nixpkgs)
          inputs.nixos-m1.nixosModules.apple-silicon-support
          ./kagami-air-m1/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/macbook-nixos.nix;
          }
        ];
      };

      # DigitalOcean node
      nixosConfigurations."nki-personal-do" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          (common-nixos nixpkgs)
          inputs.arion.nixosModules.arion
          ./modules/my-tinc
          inputs.youmubot.nixosModules.default
          ./nki-personal-do/configuration.nix
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
