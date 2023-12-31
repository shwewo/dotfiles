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

  services.tlp.enable = true;
  services.flatpak.enable = true;
  services.yubikey-agent.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ foo2zjs fxlinuxprint ];  
  
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.noisetorch.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  hardware.pulseaudio.enable = false;
  sound.enable = true;

  environment.systemPackages = with pkgs; [
    appimage-run
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
    inputs.agenix.packages.x86_64-linux.default
    inputs.nix-search-cli.packages.x86_64-linux.default
  ];
}
