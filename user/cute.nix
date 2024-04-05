{ pkgs, lib, inputs, config, self, stable, unstable, USER, ... }: 

let
  misc = import ./misc.nix { 
    inherit inputs pkgs lib config self stable unstable USER; 
    rclonepass = config.age.secrets.rclone.path;
    backuppass = config.age.secrets.backup.path;
  };
  overrides = import ./overrides.nix { 
    inherit inputs pkgs lib config self stable unstable USER; 
    dbpass = config.age.secrets.precise.path;
  };
  shwewo = inputs.shwewo.packages.${pkgs.system};
in {
  imports = [
    ./home.nix
  ];

  users.users.${USER}.packages = (with pkgs; [
    # Browsers
    ungoogled-chromium
    shwewo.ruchrome
    shwewo.ephemeralbrowser
    # Files
    dropbox
    overrides.dropbox-cli
    gocryptfs
    unstable.localsend
    p7zip
    rclone
    unzip
    zip
    inotify-tools
    misc.cloudsync
    misc.fitsync
    # Network
    shwewo.namespaced
    dnsutils
    inetutils
    overrides.lnxrouter # sudo lnxrouter -g 10.0.0.1 -o enp3s0f3u1u4 --country RU --ap wlp1s0 <ssid> -p <password> --freq-band <band> 
    wirelesstools
    gost # gost -L redirect://:3333 -F socks5://192.168.150.2:3333 trans proxy (UDP doesn't work)
    wireproxy
    wireguard-tools
    iw
    networkmanagerapplet
    nmap
    wget
    trayscale
    iodine
    ptunnel
    remmina
    # Messengers
    element-desktop
    shwewo.tdesktop
    overrides.vesktop
    # Administration
    mission-center
    usbutils
    pciutils
    util-linux
    stable.libnotify
    lm_sensors
    htop
    killall
    lsof
    virt-manager
    neofetch
    # Utilities
    inputs.agenix.packages.${pkgs.system}.default
    misc.virt
    appimage-run
    scrcpy
    tldr
    gnome.zenity
    distrobox
    libreoffice
    lua5_4
    translate-shell
    overrides.autostart
    overrides.obsidian
    overrides.kitty_wrapped
    # Games
    protonup-qt
    lutris
    steam-run
    prismlauncher
    # Audio
    shwewo.spotify
    stable.spotdl
    pavucontrol
    shwewo.audiorelay
    # Video
    yt-dlp
    celluloid
    overrides.obs
    # Graphics
    krita
    inkscape
    ffmpeg
    drawing
    imagemagick
    flameshot
    # Secrets
    overrides.keepassxc
    yubioath-flutter
    yubikey-manager-qt
    # Other stuff
    monero-gui
    openjfx11
    openjdk11 
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    jq # needed for kitty
  ]);

  programs = {
    wireshark = { enable = true; package = pkgs.wireshark; };
    gamemode.enable = true;
    gamescope.enable = true;
    steam.enable = true;
    adb.enable = true;
    firejail.enable = true;
  };
}