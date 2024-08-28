{ pkgs, lib, inputs, config, self, ... }:

{
  imports = [
    "${self}/generics/default.nix"
    ./hardware.nix
    ./network.nix
    ./socks.nix
    ./nginx.nix
    inputs.secrets.nixosModules.oracle-cloud
  ];

  system.stateVersion = "22.11";
  time.timeZone = "Europe/Amsterdam";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  virtualisation = {
    podman.enable = true;
    libvirtd.enable = true;
    oci-containers.containers = {
      docker-ipsec-vpn-server = {
        image = "hwdsl2/ipsec-vpn-server";
        ports = [
          "500:500/udp"
          "4500:4500/udp"
        ];
        volumes = [
          "ikev2-vpn-data:/etc/ipsec.d"
          "/run/current-system/kernel-modules/:/lib/modules:ro"
        ];
        extraOptions = [
          "--privileged"
        ];
      };
      neko-chromium = {
        image = "ghcr.io/m1k1o/neko/arm-chromium:latest";
        ports = [
          "127.0.0.1:8080:8080"
          "52000-52100:52000-52100/udp"
        ];
        environment = {
          NEKO_SCREEN = "1920x1080@30";
          NEKO_EPR = "52000-52100";
          NEKO_ICELITE = "true";
          NEKO_NAT1TO1 = inputs.secrets.hosts.oracle-cloud.network.ip;
          NEKO_CONTROL_PROTECTION = "true";
        };
        environmentFiles = [
          "${config.age.secrets.neko_chromium.path}"
        ];
      };
      neko-xfce = {
        image = "ghcr.io/m1k1o/neko/arm-xfce:latest";
        ports = [
          "127.0.0.1:9090:8080"
          "55000-55100:55000-55100/udp"
        ];
        environment = {
          NEKO_SCREEN = "1920x1080@30";
          NEKO_EPR = "55000-55100";
          NEKO_ICELITE = "true";
          NEKO_NAT1TO1 = inputs.secrets.hosts.oracle-cloud.network.ip;
          NEKO_CONTROL_PROTECTION = "true";
        };
        environmentFiles = [
          "${config.age.secrets.neko_xfce.path}"
        ];
      };
    };
  };

  systemd.services.podman-dcef.serviceConfig.Group = lib.mkForce "no-net";

  system.activationScripts.foo_home_read = pkgs.lib.stringAfter [ "users" ] ''
    chmod 755 /home/minecraft/
  '';

  environment.systemPackages = with pkgs; [
    mediamtx
  ];

  users.users.minecraft = {
    isNormalUser = true;
    extraGroups = [ "minecraft" ];
    description = "Minecraft user";
    packages = with pkgs; [
      openjdk8-bootstrap
    ];
    shell = pkgs.fish;
  };

  services.gitea = {
    enable = true;
    settings = {
      service.DISABLE_REGISTRATION = true;
      server = {
        DOMAIN = inputs.secrets.hosts.oracle-cloud.gitea.domain;
        DISABLE_SSH = true;
      };
    };
    database = {
      type = "sqlite3";
    };
    appName = "Yet another gitea instance";
  };

  services.matrix-conduit = {
    enable = true;
    package = inputs.conduwuit.packages.${pkgs.system}.default; 
    settings = {
      global = {
        server_name = "***REMOVED***";
      };
    };
  };

  services.adguardhome.enable = true;
  services.adguardhome.settings.http.address = "100.122.26.102:4000";
}
