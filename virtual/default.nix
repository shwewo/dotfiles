{ pkgs, lib, self, inputs, modulesPath, ... }:

{
  imports = [
    inputs.nixos-shell.nixosModules.nixos-shell
    "${self}/generics/default.nix"
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  users.users.virtual = {
    isNormalUser = true;
    description = "virtual";
    extraGroups = [ "networkmanager" "wheel" "audio" "libvirtd" "wireshark" "dialout" "plugdev" "adbusers" ];
    initialHashedPassword = "";
  };

  nixos-shell.mounts = {
    mountHome = false;
    mountNixProfile = false;
    cache = "none"; # default is "loose"
  };

  virtualisation.memorySize = 4096;
  virtualisation.cores = 3;
  virtualisation.diskSize = 4 * 1024;

  networking.hostName = "ephemeral"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/Amsterdam";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.pulseaudio.enable = false;

  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager = {
      defaultSession = "xfce";
      autoLogin = { 
        enable = true;
        user = "virtual";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    firefox
    xfce.xfce4-clipman-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-xkb-plugin
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  fileSystems."/" = { 
    device = "/dev/sda2"; 
    fsType = "ext4"; 
  };

  fileSystems."/boot/" = { 
    device = "/dev/sda1"; 
    fsType = "vfat"; 
  };

  boot.tmp.cleanOnBoot = true;

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  system.stateVersion = "23.11"; # Did you read the comment?
}