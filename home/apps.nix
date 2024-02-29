{ stable, inputs, config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Browsers
    ungoogled-chromium
    # Files
    yt-dlp
    gocryptfs
    maestral-gui
    gnome.nautilus
    gnome.file-roller
    localsend
    p7zip
    rclone
    unzip
    zip
    inotify-tools
    stable.spotdl
    # Messengers
    vesktop
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
    android-tools
    lua5_4
    translate-shell
    # Network
    nmap
    wget
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
    openjfx11
    openjdk11 
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    jq # needed for kitty

    (callPackage ../derivations/audiorelay.nix {})
    (callPackage ../derivations/spotify.nix {})
  ];
}