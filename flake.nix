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
    nur.url = "github:nix-community/NUR";

    # ---
    # Imported apps
    rnix-lsp.url = "github:nix-community/rnix-lsp";
  };

  outputs = { self, darwin, nixpkgs, nixpkgs-unstable, home-manager-unstable, home-manager-21_05, sops-nix, nur, ... }@inputs : {
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
        (let
          overlay-unstable = final: prev: {
            unstable = import nixpkgs-unstable { config.allowUnfree = true; system = prev.system; };
            unfree = import nixpkgs { config.allowUnfree = true; system = prev.system; };
          };
          overlay-needs-unstable = final: prev: {
            # override some packages that needs unstable that cannot be changed in the setup.
            nix-direnv = prev.unstable.nix-direnv;
          };
          overlay-imported = final: prev: {
            rnix-lsp = inputs.rnix-lsp.defaultPackage."x86_64-linux";
          };
        in
        {
          nixpkgs.overlays = [ overlay-unstable overlay-needs-unstable overlay-imported nur.overlay ]; # we assign the overlay created before to the overlays of nixpkgs.
        }) 
      ];
    };
  };
}
