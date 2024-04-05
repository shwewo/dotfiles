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

  start_novpn = pkgs.writeScriptBin "start_novpn" ''
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
    echo "nameserver 1.1.1.1" > /etc/netns/novpn/resolv.conf
    echo "nameserver 1.1.0.1" >> /etc/netns/novpn/resolv.conf
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

    ip monitor route | while read -r event; do
      case "$event" in 
          'local '*)
            ${delete_rules}/bin/delete_rules
            set_gateway
            add_rules
          ;;
      esac
    done
  '';

  stop_novpn = pkgs.writeScriptBin "stop_novpn" ''
    #!${pkgs.bash}/bin/bash
    ${delete_rules}/bin/delete_rules
    rm -rf /etc/netns/novpn/
    rm -rf /var/lib/novpn/
    ip link del novpn0
    ip netns del novpn
    rm -rf /var/run/netns/novpn/
  '';
in {
  systemd.services.novpn = {
    enable = true;
    description = "novpn namespace";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target"];

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15";
      ExecStart = "${start_novpn}/bin/start_novpn";
      ExecStop = "${stop_novpn}/bin/stop_novpn";
      StateDirectory = "novpn";
      Type = "simple";
    };
    
    preStart = ''
      ${stop_novpn}/bin/stop_novpn 
      ip netns add novpn
      while true; do
        interface=$(ip route show default | awk '{print $5; exit}')
        if [ -n "$interface" ]; then
          break
        fi
      done
    '';
    path = with pkgs; [ gawk iproute2 iptables sysctl coreutils ];
  };
}