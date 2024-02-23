{ inputs, home, config, lib, pkgs, specialArgs, ... }: 

{
  xdg.dataFile."cloudsync" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      ${pkgs.libnotify}/bin/notify-send "Syncing" "Compressing sync folder" --icon=globe
      ${pkgs.p7zip}/bin/7z a -mhe=on /tmp/Sync.7z ~/Dropbox/Sync -p$(cat /run/agenix/backup)

      rclone_pass=$(cat /run/agenix/rclone);
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
  };

  xdg.dataFile."fitsync" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      if [ ! -f "/home/cute/Dropbox/Sync/recovery.kdbx" ]; then
        echo "Warning, 'recovery keys' database not found!"
        exit
      fi

      fusermount -uz ~/.encryptedfit
      ${pkgs.gocryptfs}/bin/gocryptfs -passfile=/run/agenix/backup /run/media/cute/samsungfit/Encrypted ~/.encryptedfit && \
      ${pkgs.rsync}/bin/rsync -r -t -v --progress -s ~/Dropbox --delete ~/.encryptedfit/ --exclude "Sync/" --exclude ".dropbox.cache" && \
      ${pkgs.rsync}/bin/rsync -r -t -v --progress -s ~/Dropbox/Sync --delete /run/media/cute/samsungfit && \
      sync && \
      fusermount -uz ~/.encryptedfit && \
      echo "Sync complete"
      ${pkgs.libnotify}/bin/notify-send "Syncing" "USB sync complete" --icon=usb
    '';
  };

  xdg.dataFile."kitty" = {
    enable = true;
    executable = true;
    text = ''
      APP="kitty"
      APP_CMD="kitty --start-as maximized"  # Replace with the actual command to start your app, if different

      # Check if the application is running
      APP_PID=$(pgrep "$APP")

      if [[ -z $APP_PID ]]; then
          # If the application isn't running, start it
          $APP_CMD &
      else
        gdbus call --session --dest org.gnome.Shell --object-path /de/lucaswerkmeister/ActivateWindowByTitle --method de.lucaswerkmeister.ActivateWindowByTitle.activateByWmClass 'kitty'
      fi
    '';
  };

  xdg.dataFile."sign" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      echo "Disabling tailscale..."
      tailscale up --accept-dns=false --operator=cute --exit-node-allow-lan-access=false --exit-node= 
      echo "Booting VM..."
      echo "Do not forget to connect device"
      virsh --connect qemu:///system start "win10"
      virt-manager --connect qemu:///system --show-domain-console "win10"
      echo "Waiting for VM to shut down..."
      while true; do
        state=$(virsh --connect qemu:///system domstate "win10")

        if [ "$state" == "shut off" ]; then
          echo "The virtual machine win10 is now shut off."
          break
        fi

        sleep 5
      done
      tailscale up --accept-dns=false --operator=cute --exit-node-allow-lan-access --exit-node=100.93.33.171
      echo "Done."
    '';
  };

  xdg.dataFile."yubinotify" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh

      ${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector -stdout | while read line; do
      if [[ $line == U2F_1* ]]; then
        ${pkgs.libnotify}/bin/notify-send "YubiKey" "Waiting for touch..." --icon=fingerprint -t 8000
      fi

      done
    '';
  };

  xdg.dataFile."chrome" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      mkdir /tmp/chrometrick/ && firejail --private=/tmp/chrometrick --profile=google-chrome ${pkgs.google-chrome}/bin/google-chrome-stable && rm -rf /tmp/chrometrick/
    '';
  };
}
