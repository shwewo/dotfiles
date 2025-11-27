{ pkgs, config, inputs, self, ... }:

{
  imports = [
    "${self}/generics/default.nix"
    ./hardware.nix
    ./network.nix
    ./services.nix
    ./nginx.nix
    ./ebmc.nix
    ./proxy.nix
    inputs.secrets.nixosModules.ampere-24g
  ];

  time.timeZone = "Europe/Stockholm";

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        ipv6_enabled = true;
        subnets = [
          { gateway = "10.88.0.1"; subnet = "10.88.0.0/16"; }
          { gateway = "fd96:7c2e:b8d2:bf65::1"; subnet = "fd96:7c2e:b8d2:bf65::/64"; }
        ];
      };
    };
  };
}
