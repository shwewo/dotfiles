{ self, inputs, config, lib, pkgs, ... }:

{
  imports = [ 
    "${self}/generics/default.nix"
    ./hardware.nix
    ./services.nix
    ./network.nix
    ./secureboot.nix
    ./nginx.nix
    inputs.secrets.nixosModules.twinkcentre
  ];

  time.timeZone = "Europe/Moscow";

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    libvirtd = {
      enable = true;
    };
    spiceUSBRedirection.enable = true;
  };

  hardware.graphics.enable = true;

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    }
  ];

  services.udev.packages = with pkgs; [ android-udev-rules ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="PC Speaker", ENV{DEVNAME}!="", TAG+="uaccess"
  '';

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}
