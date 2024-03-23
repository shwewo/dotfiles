{ 
  description = "Shwewo's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs2105.url = "github:nixos/nixpkgs/nixos-21.05";
    
    tdesktop.url = "github:shwewo/telegram-desktop-patched";
    secrets.url = "git+ssh://git@github.com/shwewo/secrets";
    agenix.url = "github:ryantm/agenix";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, ... }: 
  let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
    specialArgs = { inherit inputs self; };
  in {
    devShells."${pkgs.system}".default = pkgs.mkShell {
      name = "shwewo";
      packages = with pkgs; [ gitleaks pre-commit ];
      shellHook = ''pre-commit install &> /dev/null && gitleaks detect -v'';
    };
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; specialArgs = specialArgs; modules = [ ./laptop/system.nix ];
    };
    nixosConfigurations.oracle-cloud = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux"; specialArgs = specialArgs; modules = [ ./oracle-cloud/system.nix ];
    };
  };
}