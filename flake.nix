{ 
  description = "Shwewo's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    tdesktop.url = "github:shwewo/telegram-desktop-patched";
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
      modules = [ ./laptop/system.nix ];
    };
    nixosConfigurations.oracle-cloud = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { 
        inherit inputs; 
        stable = import inputs.stable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
        unstable = import inputs.unstable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
      };
      modules = [ ./oracle-cloud/system.nix ];
    };
  };
}
