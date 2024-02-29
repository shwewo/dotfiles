{ inputs, home, config, lib, pkgs, specialArgs, ... }: 

let 
  ephemeralbrowser = pkgs.writeScriptBin "ephemeralbrowser" ''
    #!${pkgs.bash}/bin/bash
    google_chrome="--profile=google-chrome --private=/tmp/ephemeralbrowser ${pkgs.google-chrome}/bin/google-chrome-stable"
    ungoogled_chromium="--profile=chromium --private=/tmp/ephemeralbrowser ${pkgs.ungoogled-chromium}/bin/chromium"

    browser=$(${pkgs.gnome.zenity}/bin/zenity --list --title="Select Browser" --text="Choose browser:" --column="Browser" "google_chrome" "ungoogled_chromium")
    interface=$(${pkgs.gnome.zenity}/bin/zenity --list --title="Network Interfaces" --text="Select network interface:" --column="Interface" "default" $(${pkgs.iproute2}/bin/ip -o -4 addr show | ${pkgs.gawk}/bin/awk '$4 ~ /\/24/ {print $2}' | ${pkgs.coreutils}/bin/cut -d: -f1))
    dns=$(${pkgs.gnome.zenity}/bin/zenity --list --title="Select DNS" --text="Choose DNS server:" --column="DNS Server" "1.1.1.1" "8.8.8.8" "77.88.8.1")

    echo "Selected browser: $browser"
    echo "Selected interface: $interface"
    echo "Selected dns: $dns"

    if [[ $interface != "default" ]]; then
      google_chrome="--net=$interface $google_chrome"
      ungoogled_chromium="--net=$interface $ungoogled_chromium"
    fi

    google_chrome="firejail --ignore='include whitelist-run-common.inc' --dns=$dns $google_chrome"
    ungoogled_chromium="firejail --ignore='include whitelist-run-common.inc' --dns=$dns $ungoogled_chromium"
    
    mkdir /tmp/ephemeralbrowser
    ${pkgs.libnotify}/bin/notify-send "Ephemeral Browser" --icon=google-chrome-unstable "Browser: $browser | Interface: $interface | DNS: $dns"
   
    if [[ $browser == "google_chrome" ]]; then
      eval "$google_chrome"
    elif [[ $browser == "ungoogled_chromium" ]]; then
      eval "$ungoogled_chromium"
    fi
  '';
  
  cloudsync = pkgs.writeScriptBin "cloudsync" ''
    #!${pkgs.bash}/bin/bash
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

  fitsync = pkgs.writeScriptBin "fitsync" ''
    #!${pkgs.bash}/bin/bash
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

  kitty_wrapped = pkgs.writeScriptBin "kitty_wrapped" ''
    #!${pkgs.bash}/bin/bash
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
in {
  home.packages = [
    ephemeralbrowser
    cloudsync
    fitsync
    kitty_wrapped
  ];
}
