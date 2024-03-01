{ stable, inputs, home, config, lib, pkgs, specialArgs, ... }:

{
  home.username = "cute";
  home.stateVersion = "23.11";

  imports = [
    ./apps.nix
    ./scripts.nix
    ./programs.nix
  ];
}
