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

  # system.activationScripts.make-s-ui-network = let
  #   docker = config.virtualisation.oci-containers.backend;
  #   dockerBin = "${pkgs.${docker}}/bin/${docker}";
  # in ''
  #   ${dockerBin} network inspect s-ui >/dev/null 2>&1 || ${dockerBin} network create s-ui --subnet 172.24.0.0/16
  # '';

  virtualisation = {
    podman.enable = true;
    libvirtd.enable = true;
    oci-containers.containers = {
      x-ui = {
        image = "ghcr.io/mhsanaei/3x-ui:latest";
        ports = [
          "127.0.0.1:2053:2053"
          "10.0.0.12:443:443"
          "10.0.0.120:443:443"
        ];
        environment = {
          XRAY_VMESS_AEAD_FORCED = "false";
        };
        volumes = [
          "db:/etc/x-ui/"
          "cert:/etc/x-ui-cert/"
        ];
      };
      # s-ui = {
      #   image = "docker.io/alireza7/s-ui:latest";
      #   volumes = [
      #     "singbox:/app/bin"
      #     "db:/app/db"
      #     "cert:/app/cert"
      #   ];
      #   dependsOn = [ 
      #     "s-ui-singbox"
      #   ];
      #   extraOptions = [ "--pod=s-ui" ];
      # };
      # s-ui-singbox = {
      #   image = "docker.io/alireza7/s-ui-singbox:latest";
      #   volumes = [
      #     "singbox:/app"
      #     "cert:/cert"
      #   ];
      #   extraOptions = [ "--pod=s-ui" ];
      # };
      neko-chromium = {
        image = "ghcr.io/m1k1o/neko/arm-chromium:latest";
        ports = [
          "127.0.0.1:8080:8080"
          "10.0.0.187:52000-52100:52000-52100/udp"
        ];
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
