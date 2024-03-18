{ pkgs, lib, ... }:
let
  socksBuilder = attrs:
    let
      prefixedScript = "default_interface=$(ip route show default | awk '/default/ {print $5}')\n" + attrs.script;
    in
    {
      inherit (attrs) name;
      value = {
        enable = true;
        description = "avoid censorship";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = { Restart = "on-failure"; RestartSec = "15"; User = "socks"; Group = "socks"; Type = "simple"; };
        script = prefixedScript;
        path = with pkgs; [shadowsocks-libev shadowsocks-v2ray-plugin sing-box wireproxy iproute2 gawk];
      };
    };

  socksed = [
    { name = "socks-v2ray-sweden";   script = "ss-local -c /run/agenix/socks_v2ray_sweden -i $default_interface"; } # port 1080
    { name = "socks-v2ray-canada";   script = "ss-local -c /run/agenix/socks_v2ray_canada -i $default_interface"; } # port 1081
    { name = "socks-v2ray-france";   script = "ss-local -c /run/agenix/socks_v2ray_france -i $default_interface"; } # port 1082
    { name = "socks-v2ray-turkey";   script = "ss-local -c /run/agenix/socks_v2ray_turkey -i $default_interface"; } # port 1083
    { name = "socks-warp";           script = "wireproxy -c /etc/wireguard/warp0.conf"; } # port 3333
    { name = "socks-reality-sweden"; script = ''
      cp -f /run/agenix/socks_reality_sweden /tmp/socks_reality_sweden
      sed -i "s/DEFAULT_INTERFACE/$default_interface/" /tmp/socks_reality_sweden
      sing-box run --config /tmp/socks_reality_sweden
    ''; } # port 2080
  ];
in {
  users.users.socks = {
    group = "socks";
    isSystemUser = true;
  };  
  users.groups.socks = {};
  systemd.services = builtins.listToAttrs (map socksBuilder socksed);

  systemd.services.novpn = {
    enable = true;
    description = "novpn namespace";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15";
    };

    script = ''
      #!${pkgs.bash}/bin/bash

      NETNS_NAME="novpn"
      NETNS_NAMESERVER_1="1.1.1.1"
      NETNS_NAMESERVER_2="1.1.0.1"

      VETH0_NAME="novpn0"
      VETH1_NAME="novpn1"
      VETH0_IP="192.168.150.1"
      VETH1_IP="192.168.150.2"

      ########################################################################################################################

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
      }

      ########################################################################################################################

      cleanup() {
        echo "Terminating all processes inside of $NETNS_NAME namespace..."
        pids=$(find -L /proc/[1-9]*/task/*/ns/net -samefile /run/netns/$NETNS_NAME | cut -d/ -f5) &> /dev/null
        kill -SIGINT -$pids &> /dev/null
        kill -SIGTERM -$pids &> /dev/null
        echo "Waiting 3 seconds before SIGKILL..."
        sleep 3
        kill -SIGKILL -$pids &> /dev/null
        delete_netns
        exit 0
      }

      ########################################################################################################################

      get_default_interface
      trap cleanup INT
      create_netns
      sleep 2 # wait before they actually start to make sense
      ip monitor route | while read -r event; do
        case "$event" in
            'local '*)
              default_interface_new=$(ip route | awk '/default/ {print $5}')
              default_gateway_new=$(ip route | awk '/default/ {print $3}')

              if [[ ! -z "$default_gateway_new" ]]; then
                if [[ ! "$default_gateway_new" == "$default_gateway" ]]; then
                  default_interface=$default_gateway_new
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
  };
}