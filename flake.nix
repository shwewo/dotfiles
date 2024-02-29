{ 
  description = "Shwewo's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    agenix.url = "github:ryantm/agenix";

    telegram-desktop-patched.url = "github:shwewo/telegram-desktop-patched";
    meow.url = "git+ssh://git@github.com/shwewo/meow";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, home-manager, ... }: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { 
        inherit inputs;   
        stable = import inputs.stable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
        unstable = import inputs.unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
      };
      modules = [
        ./hosts/laptop/system.nix
        ./hosts/laptop/hardware.nix
        ./hosts/laptop/network.nix
        ./hosts/laptop/gnome.nix
        ./hosts/generic.nix
        ./modules/laptop/socks.nix
        ./modules/laptop/services.nix
        ./modules/laptop/age.nix
        inputs.agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        inputs.nh.nixosModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.cute = import ./home/cute.nix;
          home-manager.extraSpecialArgs = { 
            inherit inputs;
            stable = import inputs.stable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
            unstable = import inputs.unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
          };
          nh = {
            enable = true;
            clean.enable = true;
            clean.extraArgs = "--keep-since 4d --keep 3";
          };
        }
      ];
    };
    nixosConfigurations.oracle-cloud = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { 
        inherit inputs; 
        stable = import inputs.stable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
        unstable = import inputs.unstable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
      };
      modules = [
        ./hosts/oracle-cloud/system.nix
        ./hosts/oracle-cloud/hardware.nix
        ./hosts/oracle-cloud/network.nix
        ./hosts/generic.nix
        ./modules/oracle-cloud/socks.nix
        ./modules/oracle-cloud/nginx.nix
        ./modules/oracle-cloud/age.nix
        inputs.agenix.nixosModules.default
      ];
    };
  };
}
