{ pkgs, ... }:
let
  delete_rules = pkgs.writeScriptBin "delete_rules" ''
    #!${pkgs.bash}/bin/bash
    default_gateway=$(cat /var/lib/novpn/default_gateway)
    default_interface=$(cat /var/lib/novpn/default_interface)

    ip rule del fwmark 150 table 150
    ip rule del from 192.168.150.2 table 150
    ip rule del to 192.168.150.2 table 150
    ip route del default via $default_gateway dev $default_interface table 150
    ip route del 192.168.150.2 via 192.168.150.1 dev novpn0 table 150
    iptables -t nat -D POSTROUTING -o "$default_interface" -j MASQUERADE
  '';

  novpn = pkgs.writeScriptBin "novpn" ''
    #!${pkgs.bash}/bin/bash
    add_rules() {
      ip rule add fwmark 150 table 150
      ip rule add from 192.168.150.2 table 150
      ip rule add to 192.168.150.2 table 150
      ip route add default via $default_gateway dev $default_interface table 150 
      ip route add 192.168.150.2 via 192.168.150.1 dev novpn0 table 150
      iptables -t nat -A POSTROUTING -o "$default_interface" -j MASQUERADE
    }

    set_gateway() {
      default_interface_new=$(ip route show default | awk '{print $5; exit}')
      default_gateway_new=$(ip route show default | awk '{print $3; exit}')

      if [[ ! -z "$default_interface_new" && ! -z "$default_gateway_new" ]]; then
        default_interface=$default_interface_new
        default_gateway=$default_gateway_new
        echo "$default_gateway" > /var/lib/novpn/default_gateway
        echo "$default_interface" > /var/lib/novpn/default_interface
      fi
    }

    mkdir -p /etc/netns/novpn/
    echo "nameserver 8.8.8.8" > /etc/netns/novpn/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/netns/novpn/resolv.conf
    sysctl -wq net.ipv4.ip_forward=1

    ip link add novpn0 type veth peer name novpn1
    ip link set novpn1 netns novpn
    ip addr add 192.168.150.1/24 dev novpn0
    ip link set novpn0 up
    ip netns exec novpn ip link set lo up
    ip netns exec novpn ip addr add 192.168.150.2/24 dev novpn1
    ip netns exec novpn ip link set novpn1 up
    ip netns exec novpn ip route add default via 192.168.150.1

    set_gateway
    add_rules
    sleep 3
    ${check_network}/bin/check_network

    ip monitor route | while read -r event; do
      case "$event" in 
          'local '*)
            ${delete_rules}/bin/delete_rules &> /dev/null
            set_gateway &> /dev/null
            add_rules &> /dev/null
            sleep 2
            ${check_network}/bin/check_network
          ;;
      esac
    done
  '';

  stop = pkgs.writeScriptBin "stop" ''
    #!${pkgs.bash}/bin/bash
    ${delete_rules}/bin/delete_rules
    rm -rf /etc/netns/novpn/
    rm -rf /var/lib/novpn/
    ip link del novpn0
    ip netns del novpn
    rm -rf /var/run/netns/novpn/
  '';

  check_network = pkgs.writeScriptBin "check_network" ''
    retry_count=0

    while true; do
      response=$(ip netns exec novpn sudo -u nobody curl -m 3 -s ipinfo.io | sudo -u nobody jq -r "(.country)")
      if [ $? -eq 0 ] && [ -n "$response" ]; then
        if [[ $response != "RU" ]]; then
          echo "Country is not RU, stopping."
          sudo -u cute DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send -t 2000 -i network-error-symbolic "No VPN service" "Country is not RU"
          systemctl stop novpn.service
          exit 1
        else
          echo "Country is RU, continuing."
          break
        fi
      else
        echo "Curl request failed, retrying..."
        ((retry_count++))
        if [ $retry_count -ge 3 ]; then
          echo "Exceeded maximum retry attempts, restarting"
          systemctl restart novpn.service
          exit 1
        fi
        sleep 1
      fi
    done
  '';
in {
  systemd.services.novpn = {
    enable = true;
    description = "novpn namespace";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15";
      ExecStart = "${novpn}/bin/novpn";
      ExecStop = "${stop}/bin/stop";
      StateDirectory = "novpn";
      Type = "simple";
    };
    
    preStart = ''
      ${stop}/bin/stop &> /dev/null
      ip netns add novpn &> /dev/null
      while true; do
        interface=$(ip route show default | awk '{print $5; exit}')
        if [ -n "$interface" ]; then
          break
        fi
      done
    '';
    path = with pkgs; [ gawk iproute2 iptables sysctl coreutils curl jq sudo libnotify ];
  };
}