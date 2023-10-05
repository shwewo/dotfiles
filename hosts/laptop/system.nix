{ stable, inputs, config, pkgs, lib, ... }:

{
  system.stateVersion = "22.11";
  time.timeZone = "Europe/Moscow";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  sound.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.usbmuxd = {
    enable = false;
    package = pkgs.usbmuxd2;
  };

  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    wacom.enable = true;
    videoDrivers = [ "amdgpu" ];
    displayManager.defaultSession = "xfce";
    config = ''
      section "OutputClass"
      Identifier "AMD"
      MatchDriver "amdgpu"
      Driver "amdgpu"
      Option "TearFree" "true"
      EndSection

      Section "InputClass"
      Identifier "Tablet"
      Driver "wacom"
      MatchDevicePath "/dev/input/event*"
      MatchUSBID "056a:037a"
      EndSection
    '';
  };
  
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    spiceUSBRedirection.enable = true;
    libvirtd.enable = true;
  };

  services.flatpak.enable = true;
  services.yubikey-agent.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ foo2zjs fxlinuxprint ];  
  programs.thunar.enable = lib.mkForce false;
  programs.wireshark.enable = true;
  programs.darling.enable = true;
  programs.wireshark.package = pkgs.wireshark;
  programs.steam.enable = true;
  programs.noisetorch.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  environment.systemPackages = with pkgs; [
    idevicerestore
    libimobiledevice
    ifuse
    wineWowPackages.stable
    distrobox
    any-nix-shell
    xorg.xinit
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
    firejail
    xfce.xfce4-xkb-plugin
    xfce.xfce4-clipman-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-mailwatch-plugin
    inputs.agenix.packages.x86_64-linux.default
   ];
}
