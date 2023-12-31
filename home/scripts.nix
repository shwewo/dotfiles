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

  # xdg.dataFile."backup_libvirt" = {
  #   enable = true;
  #   executable = true;
  #   text = ''
  #     #!/bin/sh
  #     if [ -z "$1" ]; then
  #       echo "Please provide a directory to a backup archive";
  #       ${pkgs.libnotify}/bin/notify-send "Backup" "Libvirt backup failure" --icon=drive-harddisk;
  #       exit 1
  #     fi;

  #     DIRECTORY="$1";
  #     LIBVIRT_DIRECTORY="/var/lib/libvirt";                                                                                                                                                   
  #     sudo 7z a -mhe=on "$DIRECTORY/libvirt.7z" /var/lib/libvirt/ -p$(cat /run/agenix/backup);
  #     sync;
  #     echo "Backup complete";
  #     ${pkgs.libnotify}/bin/notify-send "Backup" "Libvirt backup complete" --icon=drive-harddisk;
  #   '';
  # }; 

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
      APP_CMD="kitty"  # Replace with the actual command to start your app, if different

      # Check if the application is running
      APP_PID=$(pgrep "$APP")

      if [[ -z $APP_PID ]]; then
          # If the application isn't running, start it
          $APP_CMD &
      else
          # If the application is running, focus on it
          # Get the window ID associated with the PID
          WIN_ID=$(${pkgs.xdotool}/bin/xdotool search --pid "$APP_PID" | head -1)
          if [[ -n $WIN_ID ]]; then
              ${pkgs.xdotool}/bin/xdotool windowactivate "$WIN_ID"
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

  xdg.dataFile."screenshot" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      ${pkgs.scrot}/bin/scrot -fs - | ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png
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

  xdg.dataFile."1984" = {
    enable = true;
    executable = true;
    text = ''
      #!/bin/sh
      interface=$(${pkgs.gnome.zenity}/bin/zenity --list --title="Network Interface Selection" --text="Select a Network Interface" --column="Interface" default ethernet wifi)
      profile=$(${pkgs.gnome.zenity}/bin/zenity --list --title="Firefox Profile Selection" --text="Select a Firefox Profile" --column="Profile" russian spoofed clean)

      # if [[ $profile == "russian" ]]; then
      #   firejail --net=enp3s0f3u1u3 --dns=1.1.1.1 firefox -no-remote -P russian
      # elif [[ $profile == "spoofed" ]]; then
      #   interface=$(${pkgs.gnome.zenity}/bin/zenity --list --title="Network Interface Selection" --text="Select a Network Interface" --column="Interface" enp3s0f3u1u3 wlp1s0)
      #   firejail --net=$interface --dns=1.1.1.1 firefox -no-remote -P spoofed
      # elif [[ $profile == "clean" ]]; then
      #   interface=$(${pkgs.gnome.zenity}/bin/zenity --list --title="Network Interface Selection" --text="Select a Network Interface" --column="Interface" enp3s0f3u1u3 wlp1s0)
      #   fireja
      # fi

      if [[ $interface == "default" ]]; then
        firejail firefox -no-remote -P $profile
      elif [[ $interface == "ethernet" ]]; then
        firejail --net=enp3s0f3u1u3 --dns=1.1.1.1 firefox -no-remote -P $profile
      elif [[ $interface == "wifi" ]]; then
        firejail --net=wlp1s0 --dns=1.1.1.1 firefox -no-remote -P $profile
      fi
    '';
  };

  home.file."monitor" = {
    enable = true;
    target = "/.config/kitty/monitor";
    text = ''
      launch htop
      launch dmesg -w
      launch watch sensors
    '';
  };
}
