{ lib, inputs, self, ... }:

{
  imports = [
    "${self}/generics/default.nix"
    ./hardware.nix
    ./network.nix
    ./services.nix
    inputs.secrets.nixosModules.ampere-24g
  ];

  time.timeZone = "Europe/Stockholm";

  virtualisation = {
    podman.enable = true;
    libvirtd.enable = true;
    oci-containers.containers = {
      x-ui = {
        image = "ghcr.io/mhsanaei/3x-ui:latest";
        environment = {
          XRAY_VMESS_AEAD_FORCED = "false";
        };
        volumes = [
          "db:/etc/x-ui/"
          "cert:/etc/x-ui-cert/"
        ];
        extraOptions = [
          "--privileged"
          "--network=host"
        ];
      };
    };
  };

}
