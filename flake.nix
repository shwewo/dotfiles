{ 
  description = "Shwewo's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.11";
    unstable.url = "github:nixos/nixpkgs?rev=d70bd19e0a38ad4790d3913bf08fcbfc9eeca507";
    rolling.url = "github:nixos/nixpkgs/nixos-unstable";

    tdesktop.url = "github:shwewo/telegram-desktop-patched";
    secrets.url = "git+ssh://git@github.com/shwewo/secrets";
    agenix.url = "github:ryantm/agenix";
    impermanence.url = "github:nix-community/impermanence";
    compress.url = "github:shwewo/compress";
    #yuzu-nixpkgs.url = "github:nixos/nixpkgs?rev=8debf2f9a63d54ae4f28994290437ba54c681c7b";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    conduwuit = {
      url = "github:girlbossceo/conduwuit";
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
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; 
      specialArgs = specialArgs // { stable = stable_amd64; unstable = unstable_amd64; rolling = rolling_amd64; }; 
      modules = [ ./laptop/system.nix ];
    };
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
