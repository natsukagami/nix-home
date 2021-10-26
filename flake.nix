{
  description = "nki's darwin system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, darwin, nixpkgs, nixpkgs-unstable, home-manager }: {
    darwinConfigurations."nki-macbook" = darwin.lib.darwinSystem rec {
      system = "aarch64-darwin";
      modules = [ 
        ./darwin/configuration.nix 
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
	    home-manager.extraSpecialArgs = { inherit nixpkgs-unstable; };
            home-manager.users.nki = import ./macbook-home.nix;
          }	
      ];
      inputs = { 
	inherit darwin nixpkgs-unstable;
	nixpkgs = nixpkgs-unstable;
      };
    };
  };
}
