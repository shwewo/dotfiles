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
      #url = "/home/cute/dev/flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "stable";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "unstable";
    };

    tuwunel = {
      url = "github:matrix-construct/tuwunel";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs = inputs @ { self, nixpkgs, stable, unstable, rolling, ... }: 
  let
    USER = "cute";
    stable_amd64 = import inputs.stable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    unstable_amd64 = import inputs.unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    rolling_amd64 = import inputs.rolling { system = "x86_64-linux"; config = { allowUnfree = true; }; };

    stable_aarch64 = import inputs.stable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
    unstable_aarch64 = import inputs.unstable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
    rolling_aarch64 = import inputs.rolling { system = "aarch64-linux"; config = { allowUnfree = true; }; };

    specialArgs = { inherit inputs self USER; };
  in {
    nixosConfigurations.twinkcentre = unstable.lib.nixosSystem {
      system = "x86_64-linux"; 
      specialArgs = specialArgs // { stable = stable_amd64; unstable = unstable_amd64; rolling = rolling_amd64; }; 
      modules = [ ./twinkcentre/system.nix ];
    };
    nixosConfigurations.ampere-24g = unstable.lib.nixosSystem {
      system = "aarch64-linux"; 
      specialArgs = specialArgs // { stable = stable_aarch64; unstable = unstable_aarch64; rolling = rolling_aarch64; }; 
      modules = [ ./ampere-24g/system.nix ];
    };
  };
}
