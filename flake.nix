{
  description = "nki's systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-21_05.url = "github:nix-community/home-manager/release-21.05";
    sops-nix.url = "github:Mic92/sops-nix";
    deploy-rs.url = "github:Serokell/deploy-rs";
    nur.url = "github:nix-community/NUR";

    # ---
    # Imported apps
    naersk.url = "github:nix-community/naersk";
    rnix-lsp.url = "github:nix-community/rnix-lsp";
    rnix-lsp.inputs.naersk.follows = "naersk";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = { self, darwin, nixpkgs, nixpkgs-unstable, home-manager-unstable, home-manager-21_05, deploy-rs, sops-nix, nur, ... }@inputs:
    let
      overlayForSystem = import ./overlay.nix inputs;
    in
    {
      # MacBook configuration: nix-darwin + home-manager
      darwinConfigurations."nki-macbook" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin/configuration.nix
          home-manager-unstable.darwinModules.home-manager
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
          home-manager-21_05.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nki = import ./home/kagami-pc-home.nix;
          }
          (overlayForSystem "x86_64-linux")
        ];
      };

      # DigitalOcean node
      nixosConfigurations."nki-personal-do" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/my-tinc
          sops-nix.nixosModules.sops
          ./nki-personal-do/configuration.nix
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
