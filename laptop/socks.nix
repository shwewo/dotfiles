{ pkgs, lib, ... }:
let
  socksBuilder = attrs:
    let
      prefixedScript = "ip netns exec novpn sudo -u socks -g socks " + attrs.script;
    in
    {
      inherit (attrs) name;
      value = {
        enable = true;
        after = [ "novpn.service" ];
        bindsTo = [ "novpn.service" ];
        wantedBy = [ "novpn.service" ];
        serviceConfig = { Restart = "on-failure"; RestartSec = "15"; Type = "simple"; };
        script = prefixedScript;
        path = with pkgs; [shadowsocks-libev shadowsocks-v2ray-plugin sing-box wireproxy gawk sudo iproute2 ];
      };
    };

  socksed = [
    { name = "socks-v2ray-sweden";   script = "ss-local -c /run/agenix/socks_v2ray_sweden"; } # port 1080
    { name = "socks-v2ray-canada";   script = "ss-local -c /run/agenix/socks_v2ray_canada"; } # port 1081
    { name = "socks-v2ray-france";   script = "ss-local -c /run/agenix/socks_v2ray_france"; } # port 1082
    { name = "socks-v2ray-turkey";   script = "ss-local -c /run/agenix/socks_v2ray_turkey"; } # port 1083
    { name = "socks-warp";           script = "wireproxy -c /etc/wireguard/warp0.conf"; } # port 3333
    { name = "socks-reality-sweden"; script = "sing-box run --config /run/agenix/socks_reality_sweden"; } # port 2080
  ];

  start_novpn = pkgs.writeScriptBin "start_novpn" ''
    #!${pkgs.bash}/bin/bash
    get_default_interface() {
      default_gateway=$(ip route | awk '/default/ {print $3}')
      default_interface=$(ip route | awk '/default/ {print $5}')

      if [[ -z "$default_interface" ]]; then
        echo "No default interface, are you connected to the internet?"
        exit 1
      fi

      echo "Default gateway: $default_gateway"
      echo "Default interface: $default_interface"
    }

    ########################################################################################################################

    purge_rules() {
      ip rule del fwmark 100 table 150
      ip rule del from 192.168.150.2 table 150
      ip rule del to 192.168.150.2 table 150
      ip route del default via $default_gateway dev $default_interface table 150
      ip route del 192.168.150.2 via 192.168.150.1 dev novpn0 table 150
    }

    create_rules() {
      ip rule add fwmark 100 table 150
      ip rule add from 192.168.150.2 table 150
      ip rule add to 192.168.150.2 table 150
      ip route add default via $default_gateway dev $default_interface table 150
      ip route add 192.168.150.2 via 192.168.150.1 dev novpn0 table 150
    }

    create_netns() {
      mkdir -p /etc/netns/novpn/
      echo "nameserver 1.1.1.1" > /etc/netns/novpn/resolv.conf
      echo "nameserver 1.1.0.1" >> /etc/netns/novpn/resolv.conf
      sysctl -wq net.ipv4.ip_forward=1
      iptables -t nat -A POSTROUTING -o "$default_interface" -j MASQUERADE

      ip netns add novpn
      ip link add novpn0 type veth peer name novpn1
      ip link set novpn1 netns novpn
      ip addr add 192.168.150.1/24 dev novpn0
      ip link set novpn0 up
      ip netns exec novpn ip link set lo up
      ip netns exec novpn ip addr add 192.168.150.2/24 dev novpn1
      ip netns exec novpn ip link set novpn1 up
      ip netns exec novpn ip route add default via 192.168.150.1

      create_rules
    }

    get_default_interface
    create_netns
    sleep 2 # wait before they actually start to make sense
    ip monitor route | while read -r event; do
      case "$event" in
          'local '*)
            default_interface_new=$(ip route | awk '/default/ {print $5}')
            default_gateway_new=$(ip route | awk '/default/ {print $3}')

            if [[ ! -z "$default_gateway_new" ]]; then
              if [[ ! "$default_gateway_new" == "$default_gateway" ]]; then
                default_interface=$default_interface_new
                default_gateway=$default_gateway_new
                echo "New gateway $default_gateway_new"
              fi
            fi

            echo "Network event detected, readding rules"
            purge_rules
            create_rules
          ;;
      esac
    done
  '';

  stop_novpn = pkgs.writeScriptBin "stop_novpn" ''
    #!${pkgs.bash}/bin/bash
    rm -rf /etc/netns/novpn/
    ip rule del fwmark 100 table 150
    ip rule del from 192.168.150.2 table 150
    ip rule del to 192.168.150.2 table 150
    ip link del novpn0
    ip netns del novpn
    exit 0
  '';

  novpn = {
    enable = true;
    description = "novpn namespace";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    wants = [
      "network-online.target"
      "socks-reality-sweden.service" 
      "socks-v2ray-sweden.service" 
      "socks-v2ray-france.service" 
      "socks-v2ray-turkey.service" 
      "socks-v2ray-canada.service" 
      "socks-warp.service" 
    ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15";
      ExecStart = "${start_novpn}/bin/start_novpn";
      ExecStop = "${stop_novpn}/bin/stop_novpn";
    };
    
    preStart = "${stop_novpn}/bin/stop_novpn";

    path = with pkgs; [ gawk iproute2 iptables sysctl coreutils ];
  };
in {
  users.users.socks = {
    group = "socks";
    isSystemUser = true;
  };  
  users.groups.socks = {};
  systemd.services = builtins.listToAttrs (map socksBuilder socksed) // { novpn = novpn; };
}