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
  services.yubikey-agent.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ foo2zjs fxlinuxprint ];  
  
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.noisetorch.enable = true;
  programs.captive-browser = {
    browser = builtins.concatStringsSep " " [
    ''env XDG_CONFIG_HOME="$PREV_CONFIG_HOME"''
    ''${pkgs.ungoogled-chromium}/bin/chromium''
    ''--user-data-dir=''${XDG_DATA_HOME:-$HOME/.local/share}/chromium-captive''
    ''--proxy-server="socks5://$PROXY"''
    ''--host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE localhost"''
    ''--no-first-run''
    ''--new-window''
    ''--incognito''
    ''-no-default-browser-check''
    ''http://cache.nixos.org/''
  ];
    interface = "wlp1s0";
    enable = true;
  };

  hardware.pulseaudio.enable = false;
  sound.enable = true;

  hardware.rtl-sdr.enable = true;

  environment.systemPackages = with pkgs; [
    wireguard-tools
    appimage-run
    wine
    tor-browser-bundle-bin
    idevicerestore
    libimobiledevice
    ifuse
    pinentry
    virtiofsd
    pcsctools
    linuxPackages.usbip
    yubioath-flutter
    yubikey-personalization
    yubikey-personalization-gui
    yubico-piv-tool
    yubikey-touch-detector
    yubikey-manager-qt
    yubikey-manager
    yubico-pam
    rtl-sdr
    gnuradio
    inputs.agenix.packages.x86_64-linux.default
    inputs.nix-search-cli.packages.x86_64-linux.default
  ];

  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ]; 
}
