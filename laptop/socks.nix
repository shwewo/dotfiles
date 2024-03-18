{ pkgs, lib, ... }:
let
  socksBuilder = attrs:
    {
      inherit (attrs) name;
      value = {
        enable = true;
        after = [ "novpn.service" "network-online.target" ];
        wants = [ "novpn.service" "network-online.target" ];
        bindsTo = [ "novpn.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = { 
          Restart = "on-failure"; 
          RestartSec = "15"; 
          Type = "simple"; 
          NetworkNamespacePath = "/run/netns/novpn"; 
          User = "socks"; 
          Group = "socks"; 
        };

        script = attrs.script;
        preStart = "while true; do ip addr show dev novpn1 | grep -q 'inet' && break; sleep 1; done";

        path = with pkgs; [shadowsocks-libev shadowsocks-v2ray-plugin sing-box wireproxy iproute2 ];
      };
    };
  
  # IP of the proxies is 192.168.150.2
  
  socksed = [
    { name = "socks-v2ray-sweden";      script = "ss-local -c /run/agenix/socks_v2ray_sweden";                } # port 1080
    { name = "socks-v2ray-canada";      script = "ss-local -c /run/agenix/socks_v2ray_canada";                } # port 1081
    { name = "socks-v2ray-france";      script = "ss-local -c /run/agenix/socks_v2ray_france";                } # port 1082
    { name = "socks-v2ray-turkey";      script = "ss-local -c /run/agenix/socks_v2ray_turkey";                } # port 1083
    { name = "socks-reality-sweden";    script = "sing-box run --config /run/agenix/socks_reality_sweden";    } # port 2080
    { name = "socks-reality-austria";   script = "sing-box run --config /run/agenix/socks_reality_austria";   } # port 2081
    { name = "socks-warp";              script = "wireproxy -c /etc/wireguard/warp0.conf";                    } # port 3333
  ];

  start_novpn = pkgs.writeScriptBin "start_novpn" ''
    #!${pkgs.bash}/bin/bash
    configure_rules() {
      ip rule del fwmark 100 table 150
      ip rule del from 192.168.150.2 table 150
      ip rule del to 192.168.150.2 table 150
      ip route del default via $default_gateway dev $default_interface table 150
      ip route del 192.168.150.2 via 192.168.150.1 dev novpn0 table 150
      
      ip rule add fwmark 100 table 150
      ip rule add from 192.168.150.2 table 150
      ip rule add to 192.168.150.2 table 150
      ip route add default via $default_gateway dev $default_interface table 150
      ip route add 192.168.150.2 via 192.168.150.1 dev novpn0 table 150
    }

    default_gateway=$(ip route | awk '/default/ {print $3}')
    default_interface=$(ip route | awk '/default/ {print $5}')

    if [[ -z "$default_interface" ]]; then
      echo "No default interface"
      exit 1
    fi

    mkdir -p /etc/netns/novpn/
    echo "nameserver 1.1.1.1" > /etc/netns/novpn/resolv.conf
    echo "nameserver 1.1.0.1" >> /etc/netns/novpn/resolv.conf
    sysctl -wq net.ipv4.ip_forward=1
    iptables -t nat -A POSTROUTING -o "$default_interface" -j MASQUERADE

    ip link add novpn0 type veth peer name novpn1
    ip link set novpn1 netns novpn
    ip addr add 192.168.150.1/24 dev novpn0
    ip link set novpn0 up
    ip netns exec novpn ip link set lo up
    ip netns exec novpn ip addr add 192.168.150.2/24 dev novpn1
    ip netns exec novpn ip link set novpn1 up
    ip netns exec novpn ip route add default via 192.168.150.1

    configure_rules
    sleep 3

    ip monitor route | while read -r event; do
      case "$event" in
          'local '*)
            default_interface_new=$(ip route | awk '/default/ {print $5}')
            default_gateway_new=$(ip route | awk '/default/ {print $3}')

            if [[ ! -z "$default_gateway_new" ]]; then
              if [[ ! "$default_gateway_new" == "$default_gateway" ]]; then
                default_interface=$default_interface_new
                default_gateway=$default_gateway_new
              fi
            fi

            configure_rules
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
    rm -rf /var/run/netns/novpn/ 
    exit 0
  '';

  novpn = {
    enable = true;
    description = "novpn namespace";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    wants = map (s: "${s.name}.service") socksed;

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15";
      ExecStart = "${start_novpn}/bin/start_novpn";
      ExecStop = "${stop_novpn}/bin/stop_novpn";
      Type = "simple";
    };
    
    preStart = "${stop_novpn}/bin/stop_novpn && ip netns add novpn";
    path = with pkgs; [ gawk iproute2 iptables sysctl coreutils ];
  };
in {
  users.users.socks = {
    group = "socks";
    isSystemUser = true;
  };

  users.groups.socks = {};
  systemd.services = builtins.listToAttrs (map socksBuilder socksed) // { novpn = novpn; };

  users.users.cute.packages = [ (pkgs.makeDesktopItem {
    name = "firefox-russia";
    desktopName = "Firefox Russia";
    icon = "firefox-developer-edition";
    exec = ''firejail --blacklist="/var/run/nscd" --ignore="include whitelist-run-common.inc" --netns=novpn firefox -P russia -no-remote'';
  }) ];
}