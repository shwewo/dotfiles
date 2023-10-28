{ inputs, home, config, lib, pkgs, specialArgs, ... }:

let
  schema = pkgs.gsettings-desktop-schemas;
  patchDesktop = pkg: appName: from: to:
    with pkgs; let
      zipped = lib.zipLists from to;
      # Multiple operations to be performed by sed are specified with -e
      sed-args = builtins.map
        ({ fst, snd }: "-e 's#${fst}#${snd}#g'")
        zipped;
      concat-args = builtins.concatStringsSep " " sed-args;
    in
    lib.hiPrio
      (pkgs.runCommand "$patched-desktop-entry-for-${appName}" { } ''
        ${coreutils}/bin/mkdir -p $out/share/applications
        ${gnused}/bin/sed ${concat-args} \
         ${pkg}/share/applications/${appName}.desktop \
         > $out/share/applications/${appName}.desktop
      '');
in {
  nixpkgs.config.allowUnfree = true;
  home.username = "cute";
  home.stateVersion = "22.11";

  imports = [
    ./scripts.nix
    ./programs.nix
  ];

  home.packages = with pkgs; [
    cinny-desktop
    element-desktop
    spotdl
    wmctrl
    xdotool
    p7zip
    rclone
    obsidian
    gocryptfs
    scrcpy
    sqlite
    xclip
    scrot
    xautomation
    localsend
    gitleaks
    pre-commit
    pavucontrol
    pasystray
    playerctl
    pamixer
    gnome.file-roller
    gnome.gnome-disk-utility
    gnome.nautilus
    librewolf
    unzip
    zip
    wget
    nodejs
    nmap
    htop
    killall
    lsof
    dnsutils
    inetutils
    networkmanagerapplet
    inotify-tools
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    imagemagick
    libsixel
    trayscale
    libnotify
    weechat
    util-linux
    prismlauncher
    distrobox
    lutris
    steam-run
    android-tools
    android-studio
    remmina
    usbutils
    pciutils
    lm_sensors
    monero-gui
    openjfx11
    openjdk11
    gnome.zenity
    libreoffice
    lrzsz
    ungoogled-chromium
    mediamtx
    inkscape
    ffmpeg
    v4l-utils
    dropbox
    wireguard-tools
    lua5_4
    neofetch
    krita
    winetricks
    papirus-icon-theme
    shadowsocks-libev
    shadowsocks-v2ray-plugin
    virt-manager
    discord
    flameshot
    signal-desktop
    rustup
    tdesktop
    translate-shell
    (callPackage ../derivations/audiorelay.nix {})
    (callPackage ../derivations/spotify.nix {})
  ];

  xdg.desktopEntries = {
    keepassxc = {
      name = "KeePassXC";
      icon = "keepassxc";
      exec = ''sh -c "cat /run/agenix/precise | ${pkgs.keepassxc}/bin/keepassxc --pw-stdin ~/Dropbox/Sync/passwords.kdbx"'';
      type = "Application";
    };
  };

  # xdg.dataFile."afterkeepassxc" = {
  #   enable = true;
  #   executable = true;
  #   text = ''
  #     #!/bin/sh
  #     while ! pgrep -x .keepassxc-wrap >/dev/null; do sleep 1; done && sleep 5 && \
  #     geary --gapplication-service 
  #   '';
  # };

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  services.kdeconnect.enable = true;
}
