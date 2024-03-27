{ pkgs, inputs, ... }:

{
  imports = [
    ../generics/generic.nix
    ../generics/apps.nix
    ./hardware.nix
    ./network.nix
    ./xserver.nix
    ./socks.nix
    ./udev.nix
    ./services.nix
    inputs.nh.nixosModules.default
    inputs.secrets.nixosModules.laptop
  ];

  system.stateVersion = "23.11";
  time.timeZone = "Europe/Moscow";

  security.sudo.wheelNeedsPassword = false;

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
  
  programs.captive-browser = {
    browser = ''firejail --ignore="include whitelist-run-common.inc" --private --profile=chromium ${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/env XDG_CONFIG_HOME="$PREV_CONFIG_HOME" ${pkgs.ungoogled-chromium}/bin/chromium --user-data-dir=''${XDG_DATA_HOME:-$HOME/.local/share}/chromium-captive --proxy-server="socks5://$PROXY" --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE localhost" --no-first-run --new-window --incognito -no-default-browser-check http://cache.nixos.org/' '';
    interface = "wlp1s0";
    enable = true;
  };

  services.pcscd.enable = true; # yubikey

  environment.systemPackages = with pkgs; [
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
