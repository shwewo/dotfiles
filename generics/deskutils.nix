{ pkgs, config, unstable, USER, ... }:

{
  googleChromeRussia = [
    (pkgs.writeScriptBin "google-chrome-russia" ''
      #!/usr/bin/env bash
      mkdir -p $HOME/.google-chrome-russia/.pki/nssdb/
      ${pkgs.nssTools}/bin/certutil -d sql:$HOME/.google-chrome-russia/.pki/nssdb -A -t "C,," -n "Russian Trusted Root" -i ${builtins.fetchurl {
        url = "https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt";
        sha256 = "sha256:0135zid0166n0rwymb38kd5zrd117nfcs6pqq2y2brg8lvz46slk";
      }}
      ${pkgs.nssTools}/bin/certutil -d sql:$HOME/.google-chrome-russia/.pki/nssdb -A -t "C,," -n "Russian Trusted Sub CA" -i ${builtins.fetchurl {
        url = "https://gu-st.ru/content/lending/russian_trusted_sub_ca_pem.crt";
        sha256 = "sha256:19jffjrawgbpdlivdvpzy7kcqbyl115rixs86vpjjkvp6sgmibph";
      }}  
      firejail --blacklist="/var/run/nscd" --ignore="include whitelist-run-common.inc" --private=$HOME/.google-chrome-russia --net=$(ip route show default | awk '{print $5; exit}') --dns=77.88.8.1 --profile=google-chrome ${pkgs.google-chrome}/bin/google-chrome-stable --class=google-chrome-russia https://ifconfig.me
    '')
    (pkgs.makeDesktopItem {
      name = "google-chrome-russia";
      desktopName = "Google Chrome Russia";
      genericName = "Web Browser";
      icon = "google-chrome-unstable";
      exec = "google-chrome-russia";
    })
  ];

  autostart = [
    (pkgs.writeScriptBin "autostart" ''
      #!/usr/bin/env bash
      sleep 5
      nohup gtk-launch dropbox.desktop > /dev/null & disown
      nohup gtk-launch vesktop.desktop > /dev/null & disown
      nohup gtk-launch org.telegram.desktop.desktop > /dev/null & disown
      nohup gtk-launch spotify.desktop > /dev/null & disown
      nohup gtk-launch firefox.desktop > /dev/null & disown
      nohup gtk-launch keepassxc.desktop > /dev/null & disown
      exit 0
    '')

    (pkgs.makeDesktopItem {
      name = "autostart";
      desktopName = "Autostart";
      icon = "app-launcher";
      exec = "/etc/profiles/per-user/${USER}/bin/autostart";
      type = "Application";
    })
  ];
  
  keepassxc = [
    (pkgs.writeScriptBin "keepassxc" ''
      #!/usr/bin/env bash
      QT_QPA_PLATFORM=wayland
      cat ${config.age.secrets.precise.path} | ${pkgs.keepassxc}/bin/keepassxc --pw-stdin ~/Dropbox/Sync/passwords.kdbx &
      gdbus call --session --dest org.gnome.Shell --object-path /de/lucaswerkmeister/ActivateWindowByTitle --method de.lucaswerkmeister.ActivateWindowByTitle.activateByWmClass 'KeePassXC'
    '')
    (pkgs.makeDesktopItem {
      name = "keepassxc";
      desktopName = "KeePassXC";
      icon = "keepassxc";
      exec = "/etc/profiles/per-user/${USER}/bin/keepassxc";
      type = "Application";
    })
  ];

  cloudsync = pkgs.writeScriptBin "cloudsync"  ''
    #!/usr/bin/env bash
    ${pkgs.libnotify}/bin/notify-send "Syncing" "Compressing sync folder" --icon=globe
    ${pkgs.p7zip}/bin/7z a -mhe=on /tmp/Sync.7z ~/Dropbox/Sync -p$(cat ${config.age.secrets.backup.path})

    rclone_pass=$(cat ${config.age.secrets.rclone.path});
    ${pkgs.libnotify}/bin/notify-send "Syncing" "Syncing koofr" --icon=globe;
    echo "Syncing koofr...";
    RCLONE_CONFIG_PASS="$rclone_pass" rclone -vvvv copy /tmp/Sync.7z koofr:

    ${pkgs.libnotify}/bin/notify-send "Syncing" "Syncing pcloud" --icon=globe
    echo "Syncing pcloud..."
    RCLONE_CONFIG_PASS="$rclone_pass" rclone -vvvv copy /tmp/Sync.7z pcloud:

    ${pkgs.libnotify}/bin/notify-send "Syncing" "Syncing mega" --icon=globe
    echo "Syncing mega..."
    RCLONE_CONFIG_PASS="$rclone_pass" rclone -vvvv copy /tmp/Sync.7z mega:

    echo "Sync complete"
    ${pkgs.libnotify}/bin/notify-send "Syncing" "Cloud sync complete" --icon=globe
    sleep infinity
  '';

  fitsync = pkgs.writeScriptBin "fitsync" ''
    #!/usr/bin/env bash
    if [ ! -f "/home/${USER}/Dropbox/Sync/recovery.kdbx" ]; then
      echo "Warning, 'recovery keys' database not found!"
      exit
    fi

    sudo ${pkgs.fuse}/bin/fusermount -uz ~/.encryptedfit
    ${pkgs.gocryptfs}/bin/gocryptfs -passfile=${config.age.secrets.backup.path} /run/media/${USER}/samsungfit/Encrypted ~/.encryptedfit && \
    ${pkgs.rsync}/bin/rsync -r -t -v --progress -s ~/Dropbox --delete ~/.encryptedfit/ --exclude "Sync/" --exclude ".dropbox.cache" && \
    ${pkgs.rsync}/bin/rsync -r -t -v --progress -s ~/Dropbox/Sync --delete /run/media/${USER}/samsungfit && \
    sync && \
    sudo ${pkgs.fuse}/bin/fusermount -uz ~/.encryptedfit && \
    echo "Sync complete"
    ${pkgs.libnotify}/bin/notify-send "Syncing" "USB sync complete" --icon=usb
  '';

  kitty_wrapped = pkgs.writeScriptBin "kitty_wrapped" ''
    #!/usr/bin/env bash
    pid=$(pgrep "kitty")

    if [[ -z "$pid" ]]; then
      kitty --start-as maximized &
    else
      gdbus call --session --dest org.gnome.Shell --object-path /de/lucaswerkmeister/ActivateWindowByTitle --method de.lucaswerkmeister.ActivateWindowByTitle.activateByWmClass 'kitty'
    fi
  '';
}