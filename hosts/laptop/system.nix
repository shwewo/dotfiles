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

  # services.tlp.enable = true; # gnome requires this to be false
  services.flatpak.enable = true;
  services.yubikey-agent.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ foo2zjs fxlinuxprint ];  
  
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.noisetorch.enable = true;

  # xdg.portal.enable = true;
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  hardware.pulseaudio.enable = false;
  sound.enable = true;

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
    inputs.agenix.packages.x86_64-linux.default
    inputs.nix-search-cli.packages.x86_64-linux.default
        (telegram-desktop.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [
        (fetchpatch {
          url = "https://raw.githubusercontent.com/Layerex/telegram-desktop-patches/master/0001-Disable-sponsored-messages.patch";
          hash = "sha256-o2Wxyag6hpEDgGm8FU4vs6aCpL9aekazKiNeZPLI9po=";
        })
        (fetchpatch {
          url = "https://raw.githubusercontent.com/Layerex/telegram-desktop-patches/master/0002-Disable-saving-restrictions.patch";
          hash = "sha256-sQsyXlvhXSvouPgzYSiRB8ieICo3GDXWH5MaZtBjtqw=";
        })
        (fetchpatch {
          url = "https://raw.githubusercontent.com/Layerex/telegram-desktop-patches/master/0003-Disable-invite-peeking-restrictions.patch";
          hash = "sha256-8mJD6LOjz11yfAdY4QPK/AUz9o5W3XdupXxy7kRrbC8="; 
        })
        (fetchpatch {
          url = "https://raw.githubusercontent.com/Layerex/telegram-desktop-patches/master/0004-Disable-accounts-limit.patch";
          hash = "sha256-PZWCFdGE/TTJ1auG1JXNpnTUko2rCWla6dYKaQNzreg=";
        })
      ];
    }))
  ];

  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ]; 
}

