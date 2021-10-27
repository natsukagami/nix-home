{
  description = "My DigitalOcean nodes flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.05";
    deploy-rs.url = "github:Serokell/deploy-rs";
  };
  outputs = { self, nixpkgs, deploy-rs } : {
    # DigitalOcean node
    nixosConfigurations."nki-personal" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
    deploy.nodes."nki-personal".profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."nki-personal";
    };

    # This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
