{ self, inputs, config, lib, pkgs, ... }:

{
  imports = [ 
    "${self}/generics/default.nix"
    ./hardware.nix
    ./services.nix
    ./network.nix
    ./secureboot.nix
    ./xserver.nix
    ./nginx.nix
    inputs.secrets.nixosModules.twinkcentre
  ];

  users.users.guest = {
    isNormalUser = true;
    description = "guest";
    extraGroups = [ "libvirtd" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9blPuLoJkCfTl88JKpqnSUmybCm7ci5EgWAUvfEmwb" 
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAZX2ByyBbuOfs6ndbzn/hbLaCAFiMXFsqbjplmx9GfVTx2T1aaDKFRNFtQU1rv6y3jyQCrEbjgvIjdCM4ptDf8=" # ipod
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAF63RgzwPXkOxXz8uT2OH1IcE8oRB5Yf3pmVQKH1D1ip1mWSuA24cjhH6QexVOsuAut0uHZiS4UJqRPasBZsNI53gDy8aY4JlQKX4S0jP3xK5x4G6vp5VsLCd5HovcRUgnVMnX3zvwMuDZ+u5kMWgLlIvSx/iNiwTmbs/D5IA1YUIPEug==" # z8
    ];
  };

  time.timeZone = "Europe/Paris";

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      autoPrune.enable = true;
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = with pkgs; [ virtiofsd ];
      };
    };
    waydroid.enable = true;
    spiceUSBRedirection.enable = true;
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

  services.smartd.enable = true;
  environment.systemPackages = with pkgs; [ 
    virtiofsd 
    swtpm
    smartmontools 
  ];

  services.sanoid = {
    enable = true;  
  
    datasets."rpool/root" = {
      autosnap = true;
      autoprune = true;
      monthly = 4;
    };

    datasets."zpool/home" = {
      autosnap = true;
      autoprune = true;
      hourly = 1;
      daily = 1;
      monthly = 4;
    };

    datasets."zpool/data" = {
      autosnap = true;
      autoprune = true;
      daily = 1;
      monthly = 4;
    };
  };


  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ nil cargo rustup ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
  
  system.stateVersion = "23.11"; # Did you read the comment?
}
