{
  description = "nki's systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    deploy-rs.url = "github:Serokell/deploy-rs";
    nur.url = "github:nix-community/NUR";

    flake-utils.url = github:numtide/flake-utils;

    # ---
    # Imported apps
    rnix-lsp.url = "github:nix-community/rnix-lsp";
    youmubot.url = "github:natsukagami/youmubot";
    youmubot.inputs.nixpkgs.follows = "nixpkgs";
    nix-gaming.url = github:fufexan/nix-gaming;

    # --- Sources
    kakoune.url = github:mawww/kakoune;
    kakoune.flake = false;
    kak-lsp.url = github:kak-lsp/kak-lsp;
    kak-lsp.flake = false;

    # ---
    # DEPLOYMENT ONLY! secrets
    secrets.url = "git+ssh://git@github.com/natsukagami/nix-deploy-secrets";
  };

  outputs = { self, darwin, nixpkgs, nixpkgs-unstable, home-manager, deploy-rs, sops-nix, nur, ... }@inputs:
    let
      overlays = import ./overlay.nix inputs;

      pkgs' = system: import nixpkgs { inherit system overlays; config.allowUnfree = true; };
      pkgs-unstable = system: import nixpkgs-unstable { inherit system overlays; config.allowUnfree = true; };

      nixpkgsAsRegistry_ = stable: { ... }: {
        nix.registry.nixpkgs.flake = stable;
        nix.registry.nixpkgs-unstable.flake = nixpkgs-unstable;
        nix.nixPath = [
          "nixpkgs=${nixpkgs}"
          "nixpkgs-unstable=${nixpkgs-unstable}"
          "/nix/var/nix/profiles/per-user/root/channels"
        ];
      };
      nixpkgsAsRegistry = nixpkgsAsRegistry_ nixpkgs;

      haskellDotNix = { ... }: {
        # Binary Cache for Haskell.nix  
        nix.binaryCachePublicKeys = [
          "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        ];
        nix.binaryCaches = [
          "https://cache.iog.io"
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
      darwinConfigurations."nki-macbook" = darwin.lib.darwinSystem rec {
        system = "aarch64-darwin";
        pkgs = pkgs-unstable system;
        modules = [
          ./darwin/configuration.nix
          # Set nix path
          haskellDotNix
          (nixpkgsAsRegistry_ nixpkgs-unstable)
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/macbook-home.nix;
          }
        ];
      };

      # Home configuration
      nixosConfigurations."nki-home" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        pkgs = pkgs' system;
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
          inputs.secrets.nixosModules.x86_64-linux.common
        ];
      };
      # x1c1 configuration
      nixosConfigurations."nki-x1c1" = nixpkgs.lib.nixosSystem rec {
        pkgs = pkgs' system;
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
        ];
      };

      # DigitalOcean node
      nixosConfigurations."nki-personal-do" = nixpkgs.lib.nixosSystem rec {
        pkgs = pkgs' system;
        system = "x86_64-linux";
        modules = [
          ./modules/my-tinc
          inputs.youmubot.nixosModule.x86_64-linux
          sops-nix.nixosModules.sops
          ./nki-personal-do/configuration.nix
          inputs.secrets.nixosModules.x86_64-linux.nki-personal-do
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
