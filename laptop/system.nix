{ pkgs, lib, inputs, self, config, USER, ... }:

{
  imports = [
    "${self}/user/${USER}.nix"
    "${self}/generics/default.nix"
    ./services.nix
    ./hardware.nix
    ./persistent.nix
    ./network.nix
    ./xserver.nix
    inputs.secrets.nixosModules.laptop
  ];
  
  system.stateVersion = "23.11";
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = lib.mkForce "fr_FR.UTF-8";
  i18n.supportedLocales = lib.mkForce [
    "en_GB.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "fr_FR.UTF-8/UTF-8"
  ];
  security.sudo.wheelNeedsPassword = false;
  users.users.${USER} = { hashedPasswordFile = config.age.secrets.login.path; initialHashedPassword = lib.mkForce null; };
  users.users.root.hashedPasswordFile = config.age.secrets.login.path;

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

  services.flatpak.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ foo2zjs fxlinuxprint ];  
  services.pcscd.enable = true; # yubikey

  environment.systemPackages = with pkgs; [
    virtiofsd # for qemu
    linuxPackages.usbip
    fuse-overlayfs
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  services.udev.packages = with pkgs; [ yubikey-personalization android-udev-rules ];
}
