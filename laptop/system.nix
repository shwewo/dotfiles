{ pkgs, lib, inputs, unstable, self, config, USER, ... }:

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

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.pulseaudio.enable = false;
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
  services.udev.extraRules = ''
    # USB-Blaster
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6002", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6003", MODE="0666", GROUP="plugdev"

    # USB-Blaster II
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6010", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6810", MODE="0666", GROUP="plugdev"
  '';
}
