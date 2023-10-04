{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-22.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    meow.url = "git+ssh://git@github.com/shwewo/meow";
  };

  outputs = inputs @ { nixpkgs, nixpkgs-stable, agenix, meow, home-manager, ... }: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { 
        inherit inputs; 
        stable = inputs.nixpkgs-stable.legacyPackages."x86_64-linux";
        nix.registry.sys.flake = inputs.nixpkgs;
      };
      modules = [
        ./hosts/laptop/system.nix
        ./hosts/laptop/hardware.nix
        ./hosts/generic.nix
        ./modules/laptop/network.nix
        ./modules/laptop/age.nix
        ./modules/laptop/socks.nix
        ./modules/laptop/services.nix
        ./modules/laptop/nginx.nix
        home-manager.nixosModules.home-manager
        agenix.nixosModules.default
        { 
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.cute = import ./home/cute.nix;        
        }
      ];
    };
    nixosConfigurations.oracle-cloud = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { 
        inherit inputs; 
        stable = inputs.nixpkgs-stable.legacyPackages."x86_64-linux";
        nix.registry.sys.flake = inputs.nixpkgs;
      };
      modules = [
        ./hosts/oracle-cloud/system.nix
        ./hosts/oracle-cloud/hardware.nix
        ./hosts/generic.nix
        ./modules/oracle-cloud/age.nix
        ./modules/oracle-cloud/network.nix
        ./modules/oracle-cloud/socks.nix
        agenix.nixosModules.default
      ];
    };
    nixosConfigurations.moldova = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { 
        inherit inputs; 
        stable = inputs.nixpkgs-stable.legacyPackages."x86_64-linux";
        nix.registry.sys.flake = inputs.nixpkgs;
      };
      modules = [
        ./hosts/moldova/system.nix
        ./hosts/moldova/hardware.nix
        ./hosts/generic.nix
        ./modules/moldova/network.nix
        ./modules/moldova/age.nix
        ./modules/moldova/socks.nix
        agenix.nixosModules.default
      ];
    };
  };
}
