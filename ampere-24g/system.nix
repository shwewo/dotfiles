{ pkgs, config, inputs, self, ... }:

{
  imports = [
    "${self}/generics/default.nix"
    ./hardware.nix
    ./network.nix
    ./services.nix
    inputs.secrets.nixosModules.ampere-24g
  ];

  time.timeZone = "Europe/Stockholm";

  # system.activationScripts.create-s-ui-pod = ''
  #   ${pkgs.podman}/bin/podman pod exists s-ui || ${pkgs.podman}/bin/podman pod create -n s-ui -p '127.0.0.1:2095:2095' -p '127.0.0.1:2096:2096'
  # '';

  # systemd.services.create-marzban-tmp = {
  #   serviceConfig.Type = "oneshot";
  #   wantedBy = [ "podman-marzban.service" ];
  #   script = "${pkgs.coreutils}/bin/mkdir /tmp/.marzban-uds/ || true";
  # };

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
