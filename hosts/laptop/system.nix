{ stable, inputs, config, pkgs, lib, ... }:

{
  system.stateVersion = "22.11";
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

  services.flatpak.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ foo2zjs fxlinuxprint ];  
  
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.noisetorch.enable = true;
  programs.captive-browser = {
    browser = ''firejail --ignore="include whitelist-run-common.inc" --private --profile=chromium ${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/env XDG_CONFIG_HOME="$PREV_CONFIG_HOME" ${pkgs.ungoogled-chromium}/bin/chromium --user-data-dir=''${XDG_DATA_HOME:-$HOME/.local/share}/chromium-captive --proxy-server="socks5://$PROXY" --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE localhost" --no-first-run --new-window --incognito -no-default-browser-check http://cache.nixos.org/' '';
    interface = "wlp1s0";
    enable = true;
  };

  hardware.pulseaudio.enable = false;
  sound.enable = true;

  environment.systemPackages = with pkgs; [
    tor-browser
    virtiofsd
    linuxPackages.usbip
  ];

  users.users.cute.packages = with pkgs; [
    yubioath-flutter # for some reason flutter apps are borked in home-manager
  ];

  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ]; 
}
