{ pkgs, lib, inputs, config, ... }:

{
  ephemeralbrowser = pkgs.writeScriptBin "ephemeralbrowser" ''
    #!/usr/bin/env bash

    default_interface=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk '/default/ {print $5}')
    interfaces=$(${pkgs.iproute2}/bin/ip -o -4 addr show | ${pkgs.gawk}/bin/awk '$4 ~ /\/24/ {print $2}' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/|/g')

    # The difference between default_interface and and default chose option is that default_interface is used to get dhcp and use novpn profile, and default is for leave network as is without tweaking it (e.g. VPN/proxy/whatever)

    result=$(${pkgs.gnome.zenity}/bin/zenity --forms --title="Configuration" \
      --text="Please configure your settings" \
      --add-combo="Browser:" --combo-values="google_chrome|ungoogled_chromium|firefox" \
      --add-combo="Network Interface:" --combo-values="novpn|default|"$interfaces \
      --add-combo="DNS Server:" --combo-values="dhcp|1.1.1.1|8.8.8.8|77.88.8.1")

    if [[ -z $result ]]; then
      exit 1
    fi

    browser=$(${pkgs.coreutils}/bin/echo "$result" | cut -d'|' -f1)
    interface=$(${pkgs.coreutils}/bin/echo "$result" | cut -d'|' -f2) 
    dns=$(${pkgs.coreutils}/bin/echo "$result" | cut -d'|' -f3)

    if [[ $interface == "novpn" ]]; then
      interface=$default_interface
    fi

    if [[ $dns == "dhcp" ]]; then
      ${pkgs.coreutils}/bin/echo "Getting DNS from DHCP..."
      dns=$(${pkgs.networkmanager}/bin/nmcli device show $default_interface | ${pkgs.gnugrep}/bin/grep 'IP4.DNS\[1\]' | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.gawk}/bin/awk '{print $2}')
      ${pkgs.coreutils}/bin/echo "DHCP's dns is $dns"
    fi

    ${pkgs.coreutils}/bin/mkdir -p /tmp/ephemeralbrowser

    if [[ $browser == "google_chrome" ]]; then
      browser_path="${pkgs.google-chrome}/bin/google-chrome-stable https://ifconfig.me"
      profile="google-chrome"
    elif [[ $browser == "ungoogled_chromium" ]]; then
      browser_path="${pkgs.ungoogled-chromium}/bin/chromium https://ifconfig.me"
      profile="chromium"
    elif [[ $browser == "firefox" ]]; then
      browser_path="${pkgs.firefox}/bin/firefox -no-remote https://ifconfig.me"
      profile="firefox"
    fi

    ${pkgs.libnotify}/bin/notify-send --icon=google-chrome-unstable "Ephemeral Browser" "$browser | $interface | $dns" 

    # FOR SOME FUCKING REASON https://github.com/netblue30/firejail/issues/2869#issuecomment-546579293
    if [[ $interface != "default" ]]; then
      firejail \
        --ignore='include whitelist-run-common.inc' \
        --blacklist='/var/run/nscd' \
        --private=/tmp/ephemeralbrowser \
        --profile="$profile" \
        --net="$interface" \
        --dns="$dns" \
        bash -c "$browser_path"
    else
      firejail \
        --ignore='include whitelist-run-common.inc' \
        --blacklist='/var/run/nscd' \
        --private=/tmp/ephemeralbrowser \
        --profile="$profile" \
        --dns="$dns" \
        bash -c "$browser_path"
    fi
  '';

  ephemeralbrowserDesktopItem = pkgs.makeDesktopItem {
    name = "ephemeralbrowser";
    desktopName = "Ephemeral Browser";
    icon = "google-chrome-unstable";
    exec = "/etc/profiles/per-user/cute/bin/ephemeralbrowser";
    type = "Application";
  };

  autostart = pkgs.writeScriptBin "autostart" ''
    #!/usr/bin/env bash
    ${pkgs.coreutils}/bin/sleep 5
    PID=$$
    ${pkgs.gtk3}/bin/gtk-launch dropbox.desktop
    ${pkgs.gtk3}/bin/gtk-launch org.telegram.desktop.desktop
    ${pkgs.gtk3}/bin/gtk-launch vesktop.desktop
    ${pkgs.gtk3}/bin/gtk-launch ayugram.desktop
    ${pkgs.gtk3}/bin/gtk-launch spotify.desktop
    ${pkgs.gtk3}/bin/gtk-launch firefox.desktop
    ${pkgs.gtk3}/bin/gtk-launch keepassxc.desktop                       
    exit 0
  '';

  autostartDesktopItem = pkgs.makeDesktopItem {
    name = "autostart";
    desktopName = "Autostart";
    icon = "app-launcher";
    exec = "/etc/profiles/per-user/cute/bin/autostart";
    type = "Application";
  };

  keepassxc = pkgs.writeScriptBin "keepassxc" ''
    #!/usr/bin/env bash
    QT_QPA_PLATFORM=wayland
    ${pkgs.coreutils}/bin/cat ${config.age.secrets.precise.path} | ${pkgs.keepassxc}/bin/keepassxc --pw-stdin ~/Dropbox/Sync/passwords.kdbx &
    exit 0
  '';

  keepassxcDesktopItem = pkgs.makeDesktopItem {
    name = "keepassxc";
    desktopName = "KeePassXC";
    icon = "keepassxc";
    exec = "/etc/profiles/per-user/cute/bin/keepassxc";
    type = "Application";
  };

  # ayugram-desktop = pkgs.writeScriptBin "ayugram-desktop" ''
  #   #!/usr/bin/env bash
  #   exec env QT_QPA_PLATFORM=wayland ${inputs.ayugram-desktop.packages.${pkgs.system}.default}/bin/ayugram-desktop "$@"
  #   exit 0
  # '';

  # ayugram-desktopDesktopItem = pkgs.makeDesktopItem {
  #   name = "com.ayugram.desktop";
  #   desktopName = "Telegram Desktop";
  #   icon = "telegram-desktop";
  #   exec = "/etc/profiles/per-user/cute/bin/ayugram-desktop";
  #   type = "Application";
  #   startupWMClass = "com.ayugram";
  #   mimeTypes = [ "x-scheme-handler/tg" ];
  # };

  cloudsync = pkgs.writeScriptBin "cloudsync"  ''
    #!/usr/bin/env bash
    ${pkgs.libnotify}/bin/notify-send "Syncing" "Compressing sync folder" --icon=globe
    ${pkgs.p7zip}/bin/7z a -mhe=on /tmp/Sync.7z ~/Dropbox/Sync -p$(cat ${config.age.secrets.backup.path})

    rclone_pass=$(cat ${config.age.secrets.rclone.path});
    ${pkgs.libnotify}/bin/notify-send "Syncing" "Syncing koofr" --icon=globe;
    ${pkgs.coreutils}/bin/echo "Syncing koofr...";
    RCLONE_CONFIG_PASS="$rclone_pass" rclone -vvvv copy /tmp/Sync.7z koofr:

    ${pkgs.libnotify}/bin/notify-send "Syncing" "Syncing pcloud" --icon=globe
    ${pkgs.coreutils}/bin/echo "Syncing pcloud..."
    RCLONE_CONFIG_PASS="$rclone_pass" rclone -vvvv copy /tmp/Sync.7z pcloud:

    ${pkgs.libnotify}/bin/notify-send "Syncing" "Syncing mega" --icon=globe
    ${pkgs.coreutils}/bin/echo "Syncing mega..."
    RCLONE_CONFIG_PASS="$rclone_pass" rclone -vvvv copy /tmp/Sync.7z mega:

    ${pkgs.coreutils}/bin/echo "Sync complete"
    ${pkgs.libnotify}/bin/notify-send "Syncing" "Cloud sync complete" --icon=globe
    ${pkgs.coreutils}/bin/sleep infinity
  '';

  fitsync = pkgs.writeScriptBin "fitsync" ''
    #!/usr/bin/env bash
    if [ ! -f "/home/cute/Dropbox/Sync/recovery.kdbx" ]; then
      ${pkgs.coreutils}/bin/echo "Warning, 'recovery keys' database not found!"
      exit
    fi

    sudo ${pkgs.fuse}/bin/fusermount -uz ~/.encryptedfit
    ${pkgs.gocryptfs}/bin/gocryptfs -passfile=${config.age.secrets.backup.path} /run/media/cute/samsungfit/Encrypted ~/.encryptedfit && \
    ${pkgs.rsync}/bin/rsync -r -t -v --progress -s ~/Dropbox --delete ~/.encryptedfit/ --exclude "Sync/" --exclude ".dropbox.cache" && \
    ${pkgs.rsync}/bin/rsync -r -t -v --progress -s ~/Dropbox/Sync --delete /run/media/cute/samsungfit && \
    ${pkgs.coreutils}/bin/sync && \
    sudo ${pkgs.fuse}/bin/fusermount -uz ~/.encryptedfit && \
    ${pkgs.coreutils}/bin/echo "Sync complete"
    ${pkgs.libnotify}/bin/notify-send "Syncing" "USB sync complete" --icon=usb
  '';

  kitty_wrapped = pkgs.writeScriptBin "kitty_wrapped" ''
    #!/usr/bin/env bash
    pid=$(${pkgs.procps}/bin/pgrep "kitty")

    if [[ -z "$pid" ]]; then
      kitty --start-as maximized &
    else
      ${pkgs.glib}/bin/gdbus call --session --dest org.gnome.Shell --object-path /de/lucaswerkmeister/ActivateWindowByTitle --method de.lucaswerkmeister.ActivateWindowByTitle.activateByWmClass 'kitty'
    fi
    
    exit 0
  '';

  firefoxRussia = pkgs.writeScriptBin "firefox-russia" ''
    #!/usr/bin/env bash
    firejail --blacklist="/var/run/nscd" --ignore="include whitelist-run-common.inc" --net=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gawk}/bin/awk '/default/ {print $5}') --dns=77.88.8.1 firefox --class firefox-russia  -P russia -no-remote
  '';

  firefoxRussiaDesktopItem = pkgs.makeDesktopItem {
    name = "firefox-russia";
    desktopName = "Firefox Russia";
    icon = "firefox-developer-edition";
    exec = "firefox-russia";
  };

  namespaced = pkgs.writeScriptBin "namespaced" ''
    #!/usr/bin/env bash
    RUN_COMMAND="" # Any command you want to run
    RUN_COMMAND_USER="$SUDO_USER"
    RUN_COMMAND_REDIRECT_STDOUT=false;

    DBUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" # sudo -E should do this automatically, but in any problem just set unix:path=/run/user/1000/bus
    SEND_NOTIFICATIONS=true # requires libnotify installed
    NOTIFICATIONS_USER="$SUDO_USER" # sudo should pass $SUDO_USER, but you can set it anyway

    NETNS_NAME="nsd"
    NETNS_NAMESERVER_1="1.1.1.1"
    NETNS_NAMESERVER_2="1.1.0.1"

    VETH0_NAME="nsd0"
    VETH1_NAME="nsd1"
    VETH0_IP="192.168.238.1"
    VETH1_IP="192.168.238.2"

    DEPENDENCIES=( 
      "echo"
      "bash"
      "ip"
      "iptables"
      "exit"
      "sudo"
      "sysctl"
      "kill"
      "sleep"
      "date"
      "rm"
      "curl"
      "find"
      "awk"
      "tail"
      "timeout"
      "jq"
      "mkdir"
    )

    ########################################################################################################################

    check_binary() {
      local binary="$1"
      if ! command -v "$binary" &> /dev/null; then
        echo "Error: '$binary' not found in PATH." >&2
        exit 1
      fi
    }

    for binary in "''${DEPENDENCIES[@]}"; do
      check_binary "$binary"
    done

    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
      echo -e "Usage: sudo -E ./namespaced.sh <command_in_namespace>\n"
      echo -e "This will create \"$NETNS_NAME\" network namespace"
      echo -e "To execute some program inside of \"$NETNS_NAME\" namespace, use:\n"
      echo -e "*  sudo ip netns exec sudo -u $USER <program>"
      echo -e "*  firejail --netns=$NETNS_NAME --noprofile <program>"
      echo -e "\nYou can also change variable RUN_COMMAND in script to run something you need after connecting"
      exit 0
    fi

    if [ "$(id -u)" -ne 0 ]; then
      echo "This script must be run as root."
      exit 1
    fi

    if ip netns | grep -q "$NETNS_NAME"; then
      echo "This script is already running!"
      exit 1
    fi

    if [ ! -z "$1" ]; then
      RUN_COMMAND=$1
    fi

    ########################################################################################################################

    MAIN_PID=$$
    RUNNING=true

    log() {
      echo "[$(date +"%H:%M:%S %d/%m/%Y")]: $@"
    }

    if [ "$SEND_NOTIFICATIONS" = true ]; then
    if ! command -v "notify-send" &> /dev/null; then
        log "Warning: notify-send binary not found, notifications are disabled"
        SEND_NOTIFICATIONS=false
      fi

      if [[ -z "$DBUS_ADDRESS" ]]; then
        log "Warning: DBUS_SESSION_BUS_ADDRESS is not available which is used to send notifications and graphical apps, pass -E flag to sudo to fix it automatically"
        SEND_NOTIFICATIONS=false
      fi

      if [[ -z "$NOTIFICATIONS_USER" ]]; then
        log "Warning: NOTIFICATIONS_USER is not available, please set it manually in namespaced.sh"
        SEND_NOTIFICATIONS=false
      fi

      if [ "$SEND_NOTIFICATIONS" = false ]; then
        log "Notifications are disabled"
      fi
    fi

    notify() {
      if [ "$SEND_NOTIFICATIONS" = true ]; then
        sudo -u $NOTIFICATIONS_USER DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDRESS" notify-send --icon="$1" --urgency="$3" "namespaced.sh" "$2"
      fi
    }

    get_default_interface() {
      default_gateway=$(ip route | awk '/default/ {print $3}')
      default_interface=$(ip route | awk '/default/ {print $5}')

      if [[ -z "$default_interface" ]]; then
        log "No default interface, are you connected to the internet?"
        exit 1
      fi

      log "Default gateway: $default_gateway"
      log "Default interface: $default_interface"

      read -p "Continue? [Y/n] " choice

      if [[ $choice =~ ^[Nn]$ ]]; then
        log "Exiting..."
        exit 0
      fi
    }

    ########################################################################################################################

    purge_rules() { # Run only before deleting namespace
      ip rule del fwmark 100 table 100
      ip rule del from $VETH1_IP table 100
      ip rule del to $VETH1_IP table 100
      ip route del default via $default_gateway dev $default_interface table 100
      ip route del $VETH1_IP via $VETH0_IP dev $VETH0_NAME table 100
    }

    create_rules() { # Run after creating namespace
      ip rule add fwmark 100 table 100
      ip rule add from $VETH1_IP table 100
      ip rule add to $VETH1_IP table 100
      ip route add default via $default_gateway dev $default_interface table 100
      ip route add $VETH1_IP via $VETH0_IP dev $VETH0_NAME table 100
    }

    delete_netns() {
      rm -rf /etc/netns/$NETNS_NAME/

      purge_rules
      iptables -t nat -D POSTROUTING -o "$default_interface" -j MASQUERADE

      ip link del $VETH0_NAME
      ip netns del $NETNS_NAME
    }

    create_netns() {
      if ip netns | grep -q "$NETNS_NAME"; then
        delete_netns
      fi

      mkdir -p /etc/netns/$NETNS_NAME/
      echo "nameserver $NETNS_NAMESERVER_1" > /etc/netns/$NETNS_NAME/resolv.conf
      echo "nameserver $NETNS_NAMESERVER_2" >> /etc/netns/$NETNS_NAME/resolv.conf
      sysctl -wq net.ipv4.ip_forward=1
      iptables -t nat -A POSTROUTING -o "$default_interface" -j MASQUERADE

      ip netns add $NETNS_NAME
      ip link add $VETH0_NAME type veth peer name $VETH1_NAME
      ip link set $VETH1_NAME netns $NETNS_NAME
      ip addr add $VETH0_IP/24 dev $VETH0_NAME
      ip link set $VETH0_NAME up
      ip netns exec $NETNS_NAME ip link set lo up
      ip netns exec $NETNS_NAME ip addr add $VETH1_IP/24 dev $VETH1_NAME
      ip netns exec $NETNS_NAME ip link set $VETH1_NAME up
      ip netns exec $NETNS_NAME ip route add default via $VETH0_IP

      create_rules

      export NETNS_NAME
      timeout 3s bash -c 'ip netns exec $NETNS_NAME sudo -u nobody curl -s ipinfo.io | sudo -u nobody jq -r "\"IP: \(.ip)\nCity: \(.city)\nProvider: \(.org)\""'

      if [ $? -eq 124 ]; then
        log "Timed out, is something wrong?"
        kill -INT -$MAIN_PID
      fi
    }

    ########################################################################################################################

    cleanup() {
      if [ "$RUNNING" = true ]; then
        RUNNING=false
        log "Terminating all processes inside of $NETNS_NAME namespace..."
        pids=$(find -L /proc/[1-9]*/task/*/ns/net -samefile /run/netns/$NETNS_NAME | cut -d/ -f5) &> /dev/null
        kill -SIGINT -$pids &> /dev/null
        kill -SIGTERM -$pids &> /dev/null
        log "Waiting 3 seconds before SIGKILL..."
        sleep 3
        kill -SIGKILL -$pids &> /dev/null
        delete_netns
        log "Exiting..."
        notify "network-wired-offline" "$NETNS_NAME namespace has been terminated" "critical"
        exit 0
      fi
    }

    ########################################################################################################################

    ip_monitor() {
      sleep 2 # wait before they actually start to make sense
      ip monitor route | while read -r event; do
        case "$event" in
            'local '*)
              default_gateway_new=$(ip route | awk '/default/ {print $3}')

              if [[ ! -z "$default_gateway_new" ]]; then
                if [[ ! "$default_gateway_new" == "$default_gateway" ]]; then
                  log "New gateway $default_gateway_new, stopping"
                  notify "network-error-symbolic" "New gateway $default_gateway_new, stopping" "critical"
                  kill -INT -$MAIN_PID
                fi
              fi

              log "Network event detected, readding rules"
              purge_rules
              create_rules
            ;;
        esac
      done
    };

    ping() {
      local connected=true;
      while true; do
        if ip netns exec $NETNS_NAME ping -c 1 -W 1 $NETNS_NAMESERVER_1 &> /dev/null; then
          if [ "$connected" = false ]; then
            log "Connection restored"
            notify "network-wired" "Connection restored" "normal"
          fi
          connected=true
        else
          connected=false
          log "No ping from $NETNS_NAMESERVER_1, are we connected to the internet?"
          notify "network-error-symbolic" "Connection lost" "normal"
        fi
        sleep 15
      done
    }

    run_command() {
      log "Executing \"$RUN_COMMAND\" from user $RUN_COMMAND_USER"
      
      if [ "$RUN_COMMAND_REDIRECT_STDOUT" = true ]; then
        log "Redirecting RUN_COMMAND stdout to $PWD/namespaced_run_command.log"
      fi

      ip netns exec $NETNS_NAME sudo -E -u $RUN_COMMAND_USER bash -c "DBUS_SESSION_BUS_ADDRESS=$DBUS_ADDRESS $RUN_COMMAND" >> $PWD/namespaced_command.log 2>&1
    }

    ########################################################################################################################

    start_subshell() {
      local function_name=$1
      (
        "$function_name" &
        wait
      ) &
    }

    ########################################################################################################################

    rm -f $PWD/namespaced_command.log 2> /dev/null
    touch $PWD/namespaced_command.log
    get_default_interface
    trap cleanup INT
    create_netns
    start_subshell "ip_monitor"
    start_subshell "ping"
    if [[ ! -z "$RUN_COMMAND" ]]; then
      start_subshell "run_command"
      if [ "$RUN_COMMAND_REDIRECT_STDOUT" = false ]; then
        tail -f -n +1 $PWD/namespaced_command.log | while read -r line; do
          log "RUN_COMMAND: $line"
        done 
      fi
    fi
    wait
  '';
}