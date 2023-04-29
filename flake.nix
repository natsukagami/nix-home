{
  description = "nki's systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable-asahi.url = "github:natsukagami/nixpkgs/nixpkgs-unstable";
    # nixpkgs-unstable.follows = "nixos-m1/nixpkgs";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:natsukagami/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    deploy-rs.url = "github:Serokell/deploy-rs";
    nur.url = "github:nix-community/NUR";

    # --- Build tools
    flake-utils.url = github:numtide/flake-utils;
    crane.url = github:ipetkov/crane;
    arion.url = github:hercules-ci/arion;

    # ---
    # Imported apps
    rnix-lsp.url = "github:nix-community/rnix-lsp";
    youmubot.url = "github:natsukagami/youmubot";
    youmubot.inputs.nixpkgs.follows = "nixpkgs";
    nix-gaming.url = github:fufexan/nix-gaming;
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs-unstable";
    swayfx = {
      url = github:WillPower3309/swayfx;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    mpd-mpris = {
      url = github:natsukagami/mpd-mpris/nix;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # --- Sources
    kakoune.url = github:mawww/kakoune;
    kakoune.flake = false;
    kak-lsp.url = github:kak-lsp/kak-lsp;
    kak-lsp.flake = false;
    nixos-m1.url = github:tpwrules/nixos-apple-silicon;
    nixos-m1.inputs.nixpkgs.follows = "nixpkgs-unstable-asahi";

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
          "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        ];
        nix.settings.substituters = [
          "https://cache.iog.io"
        ];
      };
      nixpkgsAsRegistry = nixpkgsAsRegistry_ nixpkgs;

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
        ];
      };

      enableOsuStable = { lib, ... }: {
        imports = [ inputs.nix-gaming.nixosModules.pipewireLowLatency ];

        services.pipewire = {
          enable = true;
          # alsa is optional
          alsa.enable = true;
          alsa.support32Bit = true;
          # needed for osu
          pulse.enable = true;
          lowLatency.enable = true;
        };
        hardware.pulseaudio.enable = lib.mkOverride 0 false;

        nix.settings.substituters = [ "https://nix-gaming.cachix.org" ];
        nix.settings.trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];

        environment.systemPackages = [ inputs.nix-gaming.packages.x86_64-linux.osu-stable ];
      };
    in
    {
      overlays.default = lib.composeManyExtensions overlays;

      # MacBook configuration: nix-darwin + home-manager
      darwinConfigurations."nki-macbook" = darwin.lib.darwinSystem rec {
        system = "aarch64-darwin";
        modules = [
          (common-nix nixpkgs-unstable)
          ./darwin/configuration.nix
          inputs.home-manager-unstable.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/macbook-home.nix;
          }
        ];
      };

      # Home configuration
      nixosConfigurations."nki-home" = nixpkgs-unstable.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          (common-nixos nixpkgs-unstable)
          ./nki-home/configuration.nix
          enableOsuStable
          inputs.home-manager-unstable.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = { ... }: {
              imports = [
                # inputs.mpd-mpris.homeManagerModules.default
                ./home/kagami-pc-home.nix
              ];
            };
          }
        ];
      };
      # x1c1 configuration
      # nixosConfigurations."nki-x1c1" = nixpkgs.lib.nixosSystem rec {
      #   system = "x86_64-linux";
      #   modules = [
      #     (common-nixos nixpkgs)
      #     ./nki-x1c1/configuration.nix
      #     home-manager.nixosModules.home-manager
      #     {
      #       home-manager.useGlobalPkgs = true;
      #       home-manager.useUserPackages = true;
      #       home-manager.users.nki = import ./home/nki-x1c1.nix;
      #     }
      #   ];
      # };
      # macbook nixos
      nixosConfigurations."kagami-air-m1" = inputs.nixpkgs-unstable-asahi.lib.nixosSystem rec {
        system = "aarch64-linux";
        modules = [
          (common-nixos inputs.nixpkgs-unstable-asahi)
          inputs.nixos-m1.nixosModules.apple-silicon-support
          ./kagami-air-m1/configuration.nix
          inputs.home-manager-unstable.nixosModules.home-manager
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
          inputs.youmubot.nixosModule.x86_64-linux
          ./nki-personal-do/configuration.nix
          inputs.secrets.nixosModules.nki-personal-do
        ];
      };
      deploy.nodes."nki-personal-do" = {
        hostname = "nki-personal-do";
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
