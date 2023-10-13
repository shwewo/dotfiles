{ inputs, home, config, lib, pkgs, specialArgs, ... }: 

{
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

  xdg.dataFile."run" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      if [[ $# -eq 0 ]]; then
        echo "Error: Missing argument."
      else
        nix run nixpkgs#"$1" -- "''\${@:2}"
      fi
    '';
  }; 
}