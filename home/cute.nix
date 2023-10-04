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

  home.packages = with pkgs; [
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
    caffeine-ng
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
    cloudflared
    htop
    killall
    lsof
    dnsutils
    inetutils
    networkmanagerapplet
    git
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
    autossh
    neofetch
    krita
    winetricks
    tor-browser-bundle-bin
    papirus-icon-theme
    shadowsocks-libev
    shadowsocks-v2ray-plugin
    virt-manager
    discord
    flameshot
    signal-desktop
    rustup
    tdesktop
    qFlipper
    (callPackage ../derivations/audiorelay.nix {})
    (callPackage ../derivations/spotify.nix {})
  ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      matklad.rust-analyzer
      bbenoist.nix
    ];
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  programs.fish = {
    enable = true;
    
    shellAliases = {
      r = "sudo nixos-rebuild switch --flake ~/Dropbox/Dev/dotfiles/";
    };
    shellInit = ''
        set fish_cursor_normal block
        set fish_greeting
        any-nix-shell fish --info-right | source
    '';
  };

  programs.kitty = {
    enable = true;
    shellIntegration.enableFishIntegration = false;
    settings = {
      background = "#171717";
      foreground = "#DCDCCC";
      background_opacity = "0.8";
      remember_window_size = "yes";
     
      color0 = "#3F3F3F";
      color1 = "#705050";
      color2 = "#60B48A";
      color3 = "#DFAF8F";
      color4 = "#9AB8D7";
      color5 = "#DC8CC3";
      color6 = "#8CD0D3";
      color7 = "#DCDCCC";

      color8 = "#709080";
      color9 = "#DCA3A3";
      color10 = "#72D5A3";
      color11 = "#F0DFAF";
      color12 = "#94BFF3";
      color13 = "#EC93D3";
      color14 = "#93E0E3";
      color15 = "#FFFFFF";
    };
  };

  programs.mpv = { 
    enable = true;
    config = {
      hwdec = "auto";
      slang = "en,eng";
      alang = "en,eng";
      subs-fallback = "default";
      subs-with-matching-audio = "yes";
      save-position-on-quit = "yes";
    };
    scripts = with pkgs; [ 
      mpvScripts.autoload
    ];
    scriptOpts = {
      autoload = {
        disabled = "no";
        images = "no";
        videos = "yes";
        audio = "yes";
        additional_image_exts = "list,of,ext";
        additional_video_exts = "list,of,ext";
        additional_audio_exts = "list,of,ext";
        ignore_hidden = "yes";
      };
     };
  };

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

  xdg.dataFile."xfceunhide" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      PANEL="panel-$1"
      FILE="/tmp/xfce-unhide-$PANEL"

      if [[ -e $FILE ]]; then
        value=$(cat $FILE)

        if [[ $value -eq 1 ]]; then
          echo "0" > $FILE
          xfconf-query -c xfce4-panel -p /panels/$PANEL/autohide-behavior -s 0
        else
          echo "1" > $FILE
          xfconf-query -c xfce4-panel -p /panels/$PANEL/autohide-behavior -s 2
        fi
      else
        echo "1" > $FILE
        xfconf-query -c xfce4-panel -p /panels/$PANEL/autohide-behavior -s 0
      fi
    '';
  };

  xdg.dataFile."cloudsync" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      tmux new-session -s cloudsync sh -c "
        enc_pass=\$(cat /run/agenix/cloudbackup);
        notify-send \"Syncing\" \"Compressing sync folder\" --icon=globe
        7z a -mhe=on /tmp/Sync.7z ~/Dropbox/Sync -p\"\$enc_pass\";

        rclone_pass=\$(cat /run/agenix/rclone);
        notify-send \"Syncing\" \"Syncing koofr\" --icon=globe;
        echo \"Syncing koofr...\";
        RCLONE_CONFIG_PASS=\"\$rclone_pass\" rclone -vvvv copy /tmp/Sync.7z koofr:;

        notify-send \"Syncing\" \"Syncing pcloud\" --icon=globe;
        echo \"Syncing pcloud...\";
        RCLONE_CONFIG_PASS=\"\$rclone_pass\" rclone -vvvv copy /tmp/Sync.7z pcloud:;

        notify-send \"Syncing\" \"Syncing mega\" --icon=globe;
        echo \"Syncing mega...\";
        RCLONE_CONFIG_PASS=\"\$rclone_pass\" rclone -vvvv copy /tmp/Sync.7z mega:;

        echo \"Sync complete\";
        notify-send \"Syncing\" \"Cloud sync complete\" --icon=globe;
        sleep infinity;
      "
    '';
  };

  xdg.dataFile."fitsync" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      tmux new-session -s fitsync sh -c "
        if [ ! -f ~/Dropbox/Sync/recovery.kdbx ]; then
          echo \"Warning, recovery keys database not found!\";
          exit
        fi;

        fusermount -uz ~/.encryptedfit;
        gocryptfs -passfile=/run/agenix/cloudbackup /run/media/cute/samsungfit/Encrypted ~/.encryptedfit && \
        rsync -r -t -v --progress -s ~/Dropbox --delete ~/.encryptedfit/ --exclude \"Sync/\" --exclude \".dropbox.cache\" && \
        rsync -r -t -v --progress -s ~/Dropbox/Sync --delete /run/media/cute/samsungfit && \
        sync && \
        fusermount -uz ~/.encryptedfit && \
        echo \"Sync complete\";
        notify-send \"Syncing\" \"USB sync complete\" --icon=usb;
        sleep infinity;
      "
    '';
  };

  xdg.dataFile."kitty" = {
    enable = true;
    executable = true;
    text = ''
      APP="kitty"
      APP_CMD="kitty"  # Replace with the actual command to start your app, if different

      # Check if the application is running
      APP_PID=$(pgrep "$APP")

      if [[ -z $APP_PID ]]; then
          # If the application isn't running, start it
          $APP_CMD &
      else
          # If the application is running, focus on it
          # Get the window ID associated with the PID
          WIN_ID=$(xdotool search --pid "$APP_PID" | head -1)
          if [[ -n $WIN_ID ]]; then
              xdotool windowactivate "$WIN_ID"
          fi
      fi
    '';
  };

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  services.kdeconnect.enable = true;
}
