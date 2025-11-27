{ 
  description = "Shwewo's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-25.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    rolling.url = "github:nixos/nixpkgs/nixos-unstable";

    secrets.url = "git+ssh://git@github.com/shwewo/secrets";
    agenix.url = "github:ryantm/agenix";
    compress.url = "github:shwewo/compress";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shwewo = {
      url = "github:shwewo/flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "stable";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };

    tuwunel = {
      url = "github:matrix-construct/tuwunel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, stable, unstable, rolling, ... }: 
  let
    stable_amd64 = import inputs.stable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    unstable_amd64 = import inputs.unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    rolling_amd64 = import inputs.rolling { system = "x86_64-linux"; config = { allowUnfree = true; }; };

    stable_aarch64 = import inputs.stable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
    unstable_aarch64 = import inputs.unstable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
    rolling_aarch64 = import inputs.rolling { system = "aarch64-linux"; config = { allowUnfree = true; }; };

    specialArgs = { inherit inputs self; };
  in {
    nixosConfigurations.twinkcentre = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; 
      specialArgs = specialArgs // { user = "cute"; stable = stable_amd64; unstable = unstable_amd64; rolling = rolling_amd64; }; 
      modules = [ ./twinkcentre/system.nix ];
    };

    nixosConfigurations.ampere-24g = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux"; 
      specialArgs = specialArgs // { user = "cute"; stable = stable_aarch64; unstable = unstable_aarch64; rolling = rolling_aarch64; }; 
      modules = [ ./ampere-24g/system.nix ];
    };

    nixosConfigurations.layer7-x86-fra = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; 
      specialArgs = specialArgs // { user = "cunt"; stable = stable_amd64; unstable = unstable_amd64; rolling = rolling_amd64; }; 
      modules = [ ./layer7-x86-fra/system.nix ];
    };
  };
}
