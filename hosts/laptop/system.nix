{ stable, inputs, config, pkgs, lib, ... }:

{
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
    interface = "wlan0";
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    tor-browser # globally because i need to firejail it
    virtiofsd # for qemu
    linuxPackages.usbip
    android-tools
    wl-clipboard
  ];
}
