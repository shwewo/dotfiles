{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    nix-search-cli.url = "github:peterldowns/nix-search-cli";
    meow.url = "git+ssh://git@github.com/shwewo/meow";
  };

  outputs = inputs @ { nixpkgs, nixpkgs-stable, agenix, nix-search-cli, meow, home-manager, ... }: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { 
        inherit inputs; 
        stable = inputs.nixpkgs-stable.legacyPackages."x86_64-linux";
        nix.registry.sys.flake = inputs.nixpkgs;
        nix.extraOptions = ''
          keep-outputs = true
          keep-derivations = true
        '';
      };
      modules = [
        ./hosts/laptop/system.nix
        ./hosts/laptop/hardware.nix
        ./hosts/laptop/network.nix
        ./hosts/laptop/xorg.nix
        ./hosts/generic.nix
        ./modules/laptop/socks.nix
        ./modules/laptop/services.nix
        ./modules/laptop/age.nix
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.cute = import ./home/cute.nix;
          home-manager.extraSpecialArgs = { inherit inputs; }; 
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
        ./hosts/oracle-cloud/network.nix
        ./hosts/generic.nix
        ./modules/oracle-cloud/socks.nix
        ./modules/oracle-cloud/age.nix
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
        ./hosts/moldova/network.nix
        ./hosts/generic.nix
        ./modules/moldova/socks.nix
        ./modules/moldova/age.nix
        agenix.nixosModules.default
      ];
    };
  };
}
