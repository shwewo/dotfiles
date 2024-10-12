{ self, config, lib, pkgs, ... }:

{
  imports = [ 
    "${self}/generics/default.nix"
    ./hardware.nix
    ./services.nix
    ./network.nix
  ];

  time.timeZone = "Europe/Moscow";

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    spiceUSBRedirection.enable = true;
    libvirtd.enable = true;
  };

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

  services.openssh = {
    enable = true;
    extraConfig = ''
      LoginGraceTime 0
    '';
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}
