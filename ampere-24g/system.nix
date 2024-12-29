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
      neko-chromium = {
        ports = [
          "127.0.0.1:8080:8080"
          "10.0.0.187:52000-52100:52000-52100/udp"
        ];
        image = "ghcr.io/m1k1o/neko/arm-chromium:latest";
        environment = {
          NEKO_SCREEN = "1920x1080@30";
          NEKO_EPR = "52000-52100";
          NEKO_ICELITE = "true";
          NEKO_CONTROL_PROTECTION = "true";
        };
        environmentFiles = [
          "${config.age.secrets.neko_chromium.path}"
        ];
      };
    };
  };

}
