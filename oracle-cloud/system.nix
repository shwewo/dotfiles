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
    };
  };

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
        server_name = "matrix.nekolit.eu.org";
        turn_uris = [ inputs.secrets.hosts.oracle-cloud.coturn ];
        turn_secret = inputs.secrets.hosts.oracle-cloud.coturn_secret;
      };
    };
  };

  services.adguardhome.enable = true;
  services.adguardhome.settings.http.address = "100.122.26.102:4000";
}
