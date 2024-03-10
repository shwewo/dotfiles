{ stable, inputs, home, config, lib, pkgs, specialArgs, ... }:

{
  home.username = "cute";
  home.stateVersion = "23.11";

  imports = [
    ./scripts.nix
    ./programs.nix
  ];
}
