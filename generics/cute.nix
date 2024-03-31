{ pkgs, lib, inputs, config, self, stable, unstable, USER, ... }: 

let
  deskutils = import ./deskutils.nix { inherit inputs pkgs lib config self unstable USER; };
in {
  imports = [
    ./home.nix
  ];

  users.users.${USER}.packages = (with unstable; [
    # Browsers
    ungoogled-chromium
    # Files
    yt-dlp
    freetube
    dropbox
    (pkgs.writeScriptBin "dropbox-cli" "${pkgs.dropbox-cli}/bin/dropbox $@")
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
    # Network
    dnsutils
    inetutils
    (linux-router.override { useHaveged = true; }) # sudo lnxrouter -g 10.0.0.1 -o enp3s0f3u1u4 --country RU --ap wlp1s0 <ssid> -p <password> --freq-band <band> 
    wirelesstools
    gost # gost -L redirect://:3333 -F socks5://192.168.150.2:3333 trans proxy (UDP doesn't work)
    (callPackage ../derivations/microsocks.nix {})
    (curl.override { })
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
    inputs.tdesktop.packages.${pkgs.system}.default
    # Administration
    pavucontrol
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
    obsidian
    appimage-run
    scrcpy
    tldr
    gnome.zenity
    distrobox
    libreoffice
    lua5_4
    translate-shell
    # Games
    protonup-qt
    lutris
    steam-run
    prismlauncher
    # Graphics
    krita
    inkscape
    ffmpeg
    drawing
    imagemagick
    # v4l-utils
    flameshot
    # Other stuff
    monero-gui
    yubioath-flutter
    yubikey-manager-qt
    openjfx11
    openjdk11 
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    jq # needed for kitty

    (callPackage ../derivations/audiorelay.nix {})
    (callPackage ../derivations/spotify.nix { spotify = stable.spotify; })
    (callPackage ../derivations/namespaced.nix {})
    (callPackage ../derivations/ephemeralbrowser.nix {})

    (vesktop.overrideAttrs (oldAttrs: {
      desktopItems = [ (pkgs.makeDesktopItem {
        name = "vesktop";
        desktopName = "Discord";
        exec = "vesktop %U";
        icon = "discord";
        startupWMClass = "Vesktop";
        genericName = "Internet Messenger";
        keywords = [ "discord" "vencord" "electron" "chat" ];
        categories = [ "Network" "InstantMessaging" "Chat" ];
      })];
    }))

    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
      ];
    })
  ]) ++ (with deskutils; [
    cloudsync
    fitsync
    kitty_wrapped
  ] ++ deskutils.googleChromeRussia
    ++ deskutils.keepassxc
    ++ deskutils.autostart
  );

  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.noisetorch.enable = true;
  programs.adb.enable = true;
  programs.firejail.enable = true;
}