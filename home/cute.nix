{ stable, inputs, home, config, lib, pkgs, specialArgs, ... }:

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
  home.username = "cute";
  home.stateVersion = "22.11";

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
    maestral-gui
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
    inputs.telegram-desktop-patched.packages.${pkgs.system}.default
    discord
    discord-screenaudio
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
    wl-clipboard
    cachix

    (callPackage ../derivations/audiorelay.nix {})
    (callPackage ../derivations/spotify.nix {})

    (patchDesktop discord "discord"
      [
        "Exec=Discord"
      ]
      [
        "Exec=Discord --ozone-platform-hint=auto"
      ])
  ];

  xdg.desktopEntries = {
    keepassxc = {
      name = "KeePassXC";
      icon = "keepassxc";
      exec = ''sh -c "cat /run/agenix/precise | ${pkgs.keepassxc}/bin/keepassxc --pw-stdin ~/Dropbox/Sync/passwords.kdbx"'';
      type = "Application";
    };
    autostart = {
      name = "autostart";
      exec = "/home/cute/.autostart.sh";
      type = "Application";
    };
  };

  home.file."autostart" = {
    enable = true;
    target = "/.autostart.sh";
    executable = true;
    text = ''
      #!/bin/sh
      sleep 5
      gtk-launch maestral.desktop
      gtk-launch keepassxc.desktop
      gtk-launch discord.desktop
      gtk-launch org.telegram.desktop.desktop
      gtk-launch spotify.desktop
      gtk-launch firefox.desktop
    '';
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

  # services.kdeconnect.enable = true;
}
