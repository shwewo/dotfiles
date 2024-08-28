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
    ./udev.nix
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
    # lxd = {
    #   enable = true;
    # };
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
    tor-browser # globally because i need to firejail it
    wl-clipboard
    steamcmd
    virtiofsd # for qemu
    linuxPackages.usbip
    fuse-overlayfs
    (unstable.linux-router.override { useHaveged = true; }) # sudo lnxrouter -g 10.0.0.1 -o enp3s0f3u1u4 --country RU --ap wlp1s0 <ssid> -p <password> --freq-band <band> 
    inputs.shwewo.packages.${pkgs.system}.namespaced
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}
