{ pkgs, lib, inputs, self, config, USER, ... }:

{
  imports = [
    "${self}/user/${USER}.nix"
    "${self}/generics/default.nix"
    "${self}/generics/services.nix"
    ./hardware.nix
    ./persistent.nix
    ./network.nix
    ./xserver.nix
    ./udev.nix
    inputs.nh.nixosModules.default
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
  sound.enable = true;

  services.flatpak.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ foo2zjs fxlinuxprint ];  

  services.pcscd.enable = true; # yubikey

  environment.systemPackages = with pkgs; [
    sbctl # secure boot
    tor-browser # globally because i need to firejail it
    virtiofsd # for qemu
    linuxPackages.usbip
    android-tools
    wl-clipboard
    jamesdsp # audio compressor
    easyeffects
  ];

  nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}
