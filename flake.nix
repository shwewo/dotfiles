{ 
  description = "Shwewo's NixOS system configuration";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs?rev=ebce8ace41c8ca0d1776de4c5be5c815fb2fb5f7";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    staging.url = "github:nixos/nixpkgs/staging-next";
    nixpkgs2105.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs2305.url = "github:nixos/nixpkgs/nixos-23.05";

    tdesktop.url = "github:shwewo/telegram-desktop-patched";
    secrets.url = "git+ssh://git@github.com/shwewo/secrets";
    agenix.url = "github:ryantm/agenix";
    impermanence.url = "github:nix-community/impermanence";
    nixos-shell.url = "github:Mic92/nixos-shell";
    #yuzu-nixpkgs.url = "github:nixos/nixpkgs?rev=8debf2f9a63d54ae4f28994290437ba54c681c7b";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shwewo = {
      url = "github:shwewo/flake";
      # url = "/home/cute/dev/flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "stable";
    };
  };

  outputs = inputs @ { self, nixpkgs, stable, unstable, ... }: 
  let
    USER = "cute";
    stable_amd64 = import inputs.stable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    unstable_amd64 = import inputs.unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    stable_aarch64 = import inputs.stable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
    unstable_aarch64 = import inputs.unstable { system = "aarch64-linux"; config = { allowUnfree = true; }; };
    specialArgs = { inherit inputs self USER; };
  in {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; 
      specialArgs = specialArgs // { stable = stable_amd64; unstable = unstable_amd64; }; 
      modules = [ ./laptop/system.nix ];
    };
    nixosConfigurations.oracle-cloud = stable.lib.nixosSystem {
      system = "aarch64-linux"; 
      specialArgs = specialArgs // { stable = stable_aarch64; unstable = unstable_aarch64; }; 
      modules = [ ./oracle-cloud/system.nix ];
    };
    nixosConfigurations.virtserial = stable.lib.nixosSystem {
      system = "x86_64-linux"; 
      specialArgs = specialArgs // { stable = stable_amd64; unstable = unstable_amd64; }; 
      modules = [ ./virtual/default.nix ];
    };
    nixosConfigurations.virtgraphics = stable.lib.nixosSystem {
      system = "x86_64-linux"; 
      specialArgs = specialArgs // { stable = stable_amd64; unstable = unstable_amd64; }; 
      modules = [ ./virtual/graphics.nix ];
    };
  };
}
