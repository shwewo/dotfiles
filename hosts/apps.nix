# This file exists because home-manager always complains about collisions between some shit and i already don't have a life

{ stable, inputs, config, pkgs, lib, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ]; 

  users.users.cute.packages = with pkgs; [
    # Browsers
    ungoogled-chromium
    # Files
    yt-dlp
    gocryptfs
    gnome.nautilus
    gnome.file-roller
    celluloid
    localsend
    p7zip
    rclone
    unzip
    zip
    inotify-tools
    stable.spotdl
    # Messengers
    element-desktop
    inputs.telegram-desktop-patched.packages.${pkgs.system}.default
    # Administration
    pavucontrol
    mission-center  
    usbutils
    dnsutils
    pciutils
    util-linux
    libnotify
    lm_sensors
    htop
    killall
    lsof
    dnsutils
    inetutils
    virt-manager
    neofetch
    # Utilities
    obsidian
    appimage-run
    scrcpy
    gnome.zenity
    distrobox
    libreoffice
    lua5_4
    translate-shell
    # Network
    nmap
    wget
    trayscale
    remmina
    # Games
    protonup-qt
    lutris
    steam-run
    prismlauncher
    # Graphics
    krita
    inkscape
    ffmpeg
    imagemagick
    v4l-utils
    flameshot
    # Other stuff
    monero-gui
    yubioath-flutter
    openjfx11
    openjdk11 
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    jq # needed for kitty

    (callPackage ../derivations/audiorelay.nix {})
    (callPackage ../derivations/spotify.nix {})
  ];

  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.noisetorch.enable = true;
  programs.adb.enable = true;
}