{
  description = "nki's systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    deploy-rs.url = "github:Serokell/deploy-rs";
    nur.url = "github:nix-community/NUR";

    # ---
    # Imported apps
    naersk.url = "github:nix-community/naersk";
    rnix-lsp.url = "github:nix-community/rnix-lsp";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs-unstable";
    youmubot.url = "github:natsukagami/youmubot";
    nix-gaming.url = github:fufexan/nix-gaming;

    # ---
    # DEPLOYMENT ONLY! secrets
    secrets.url = "git+ssh://git@github.com/natsukagami/nix-deploy-secrets";
  };

  outputs = { self, darwin, nixpkgs, nixpkgs-unstable, home-manager, deploy-rs, sops-nix, nur, ... }@inputs:
    let
      overlayForSystem = import ./overlay.nix inputs;

      nixpkgsAsRegistry = { ... }: {
        nix.registry.nixpkgs.flake = nixpkgs;
        nix.registry.nixpkgs-unstable.flake = nixpkgs-unstable;
        nix.nixPath = [
          "nixpkgs=${nixpkgs}"
          "nixpkgs-unstable=${nixpkgs-unstable}"
          "/nix/var/nix/profiles/per-user/root/channels"
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

        nix.binaryCaches = [ "https://nix-gaming.cachix.org" ];
        nix.binaryCachePublicKeys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];

        environment.systemPackages = [ inputs.nix-gaming.packages.x86_64-linux.osu-stable ];
      };
    in
    {
      # MacBook configuration: nix-darwin + home-manager
      darwinConfigurations."nki-macbook" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/macbook-home.nix;
          }
          (overlayForSystem "aarch64-darwin")
        ];
      };

      # Home configuration
      nixosConfigurations."nki-home" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/my-tinc
          sops-nix.nixosModules.sops
          ./nki-home/configuration.nix
          nixpkgsAsRegistry
          enableOsuStable
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/kagami-pc-home.nix;
          }
          (overlayForSystem "x86_64-linux")
        ];
      };
      # x1c1 configuration
      nixosConfigurations."nki-x1c1" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/my-tinc
          sops-nix.nixosModules.sops
          ./nki-x1c1/configuration.nix
          nixpkgsAsRegistry
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/nki-x1c1.nix;
          }
          (overlayForSystem "x86_64-linux")
        ];
      };

      # DigitalOcean node
      nixosConfigurations."nki-personal-do" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/my-tinc
          inputs.youmubot.nixosModule.x86_64-linux
          sops-nix.nixosModules.sops
          ./nki-personal-do/configuration.nix
          inputs.secrets.nixosModules.x86_64-linux.nki-personal-do
          (overlayForSystem "x86_64-linux")
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

    };
}
