{ 
  description = "Shwewo's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs2105.url = "github:nixos/nixpkgs/nixos-21.05";
    
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

  outputs = inputs @ { self, nixpkgs, ... }: 
  let
    stable_amd64 = import inputs.stable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    unstable_amd64 = import inputs.unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    stable_aarch64 = import inputs.stable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
    unstable_aarch64 = import inputs.unstable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
    specialArgs = { inherit inputs self; };
  in {
    devShells."x86_64-linux".default = nixpkgs.legacyPackages."x86_64-linux".mkShell {
      name = "shwewo";
      packages = with nixpkgs.legacyPackages."x86_64-linux"; [ gitleaks pre-commit ];
      shellHook = ''pre-commit install &> /dev/null && gitleaks detect -v'';
    };
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; 
      specialArgs = specialArgs // { stable = stable_amd64; unstable = unstable_amd64; }; 
      modules = [ ./laptop/system.nix ];
    };
    nixosConfigurations.oracle-cloud = inputs.stable.lib.nixosSystem {
      system = "aarch64-linux"; 
      specialArgs = specialArgs // { stable = stable_aarch64; unstable = unstable_aarch64; }; 
      modules = [ ./oracle-cloud/system.nix ];
    };
  };
}