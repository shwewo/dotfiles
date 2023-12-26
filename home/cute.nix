{ stable, inputs, home, config, lib, pkgs, specialArgs, ... }:

let
  schema = pkgs.gsettings-desktop-schemas;
  patchDesktop = pkg: appName: from: to: with pkgs; let zipped = lib.zipLists from to; sed-args = builtins.map ({ fst, snd }: "-e 's#${fst}#${snd}#g'") zipped; concat-args = builtins.concatStringsSep " " sed-args; in lib.hiPrio (pkgs.runCommand "$patched-desktop-entry-for-${appName}" { } '' ${coreutils}/bin/mkdir -p $out/share/applications ${gnused}/bin/sed ${concat-args} \ ${pkg}/share/applications/${appName}.desktop \ > $out/share/applications/${appName}.desktop'');
in {
  home.username = "cute";
  home.stateVersion = "22.11";
  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
  };

  imports = [
    ./scripts.nix
    ./programs.nix
  ];

  home.packages = with pkgs; [
    # Browsers
    # google-chrome # ikr
    ungoogled-chromium # i have bipolar disorder
    firefox
    # Files
    yt-dlp
    gocryptfs
    dropbox
    localsend
    gnome.nautilus
    gnome.file-roller
    p7zip
    rclone
    unzip
    zip
    inotify-tools
    stable.spotdl
    # Git
    gitleaks
    pre-commit
    # Messengers
    element-desktop
    tdesktop
    discord
    # Administration
    pavucontrol
    gnome.gnome-disk-utility
    usbutils
    pciutils
    networkmanagerapplet
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
    scrcpy
    stable.trayscale
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
