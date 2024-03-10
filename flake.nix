{ 
  description = "Shwewo's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    telegram-desktop-patched.url = "github:shwewo/telegram-desktop-patched";
    secrets.url = "git+ssh://git@github.com/shwewo/secrets";
    agenix.url = "github:ryantm/agenix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, ... }: 
  let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
  in {
    devShells."x86_64-linux".default = pkgs.mkShell {
      name = "shwewo";
      packages = with pkgs; [ gitleaks pre-commit inputs.agenix.packages.${pkgs.system}.default ];
      shellHook = ''
        gitleaks detect -v
        pre-commit install &> /dev/null
      '';
    };
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
        ./hosts/laptop/socks.nix
        ./hosts/laptop/services.nix
        ./hosts/generic.nix
        ./hosts/apps.nix
        inputs.home-manager.nixosModules.home-manager
        inputs.secrets.nixosModules.laptop
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
        ./hosts/oracle-cloud/socks.nix
        ./hosts/oracle-cloud/nginx.nix
        ./hosts/generic.nix
        inputs.secrets.nixosModules.oracle-cloud
      ];
    };
  };
}
