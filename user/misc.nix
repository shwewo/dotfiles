{ pkgs, rclonepass, backuppass, USER, ... }:

{
  cloudsync = pkgs.writeScriptBin "cloudsync"  ''
    #!/usr/bin/env bash
    ${pkgs.libnotify}/bin/notify-send "Syncing" "Compressing sync folder" --icon=globe
    ${pkgs.p7zip}/bin/7z a -mhe=on /tmp/Sync.7z ~/Dropbox/Sync -p$(cat ${backuppass})

    rclone_pass=$(cat ${rclonepass});
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
    ${pkgs.gocryptfs}/bin/gocryptfs -passfile=${backuppass} /run/media/${USER}/samsungfit/Encrypted ~/.encryptedfit && \
    ${pkgs.rsync}/bin/rsync -r -t -v --progress -s ~/Dropbox --delete ~/.encryptedfit/ --exclude "Sync/" --exclude ".dropbox.cache" && \
    ${pkgs.rsync}/bin/rsync -r -t -v --progress -s ~/Dropbox/Sync --delete /run/media/${USER}/samsungfit && \
    sync && \
    sudo ${pkgs.fuse}/bin/fusermount -uz ~/.encryptedfit && \
    echo "Sync complete"
    ${pkgs.libnotify}/bin/notify-send "Syncing" "USB sync complete" --icon=usb
  '';
}