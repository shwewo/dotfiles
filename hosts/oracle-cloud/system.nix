{ inputs, config, pkgs, lib, args, ... }: 
{
  system.stateVersion = "22.11";
  time.timeZone = "Europe/Amsterdam";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
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
    };
  };

  system.activationScripts.foo_home_read = pkgs.lib.stringAfter [ "users" ] ''
    chmod 755 /home/minecraft/
  '';

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
        DOMAIN = inputs.meow.hosts.oracle-cloud.gitea.domain;
        DISABLE_SSH = true;
      };
    };
    database = {
      type = "sqlite3";
    };
    appName = "Yet another gitea instance";
  };
}


