{ pkgs, lib, config, inputs, ... }:
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
          User = "socks"; 
          Group = "socks";
          RuntimeMaxSec=3600;
          NetworkNamespacePath = "/run/netns/novpn";
        };

        script = attrs.script;
        preStart = "while true; do ip addr show dev novpn1 | grep -q 'inet' && break; sleep 1; done";

        path = with pkgs; [ 
          iproute2 
          shadowsocks-libev 
          shadowsocks-v2ray-plugin 
          sing-box 
          wireproxy
          gost
          (callPackage ../derivations/microsocks.nix {}) 
        ];
      };
    };
  
  # IP of the proxies is 192.168.150.2
  
  socksed = [
    { name = "socks-v2ray-sweden";      script = "ss-local -c           ${config.age.secrets.socks_v2ray_sweden.path}";    } # port 1080
    { name = "socks-v2ray-canada";      script = "ss-local -c           ${config.age.secrets.socks_v2ray_canada.path}";    } # port 1081
    { name = "socks-v2ray-france";      script = "ss-local -c           ${config.age.secrets.socks_v2ray_france.path}";    } # port 1082
    { name = "socks-v2ray-turkey";      script = "ss-local -c           ${config.age.secrets.socks_v2ray_turkey.path}";    } # port 1083
    { name = "socks-reality-sweden";    script = "sing-box run --config ${config.age.secrets.socks_reality_sweden.path}";  } # port 2080
    { name = "socks-reality-austria";   script = "sing-box run --config ${config.age.secrets.socks_reality_austria.path}"; } # port 2081
    { name = "socks-warp";              script = "wireproxy -c /etc/wireguard/warp0.conf";                                 } # port 3333
    { name = "socks-novpn";             script = "microsocks -i 192.168.150.2 -p 3535";                                                          } # port 3535
  ];

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
    if [[ -z "$default_interface" ]]; then
      echo "No default interface"
      exit 1
    fi
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
  users.users.socks = {
    group = "socks";
    isSystemUser = true;
  };

  users.groups.socks = {};
  systemd.services = builtins.listToAttrs (map socksBuilder socksed) // { 
    novpn = {
      enable = true;
      description = "novpn namespace";
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      wants = map (s: "${s.name}.service") socksed ++ [ "network-online.target"];

      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "15";
        ExecStart = "${start_novpn}/bin/start_novpn";
        ExecStop = "${stop_novpn}/bin/stop_novpn";
        StateDirectory = "novpn";
        Type = "simple";
      };
      
      preStart = "${stop_novpn}/bin/stop_novpn && ip netns add novpn";
      path = with pkgs; [ gawk iproute2 iptables sysctl coreutils ];
    };

    warp-svc = {
      enable = true;
      description = "Cloudflare Zero Trust Client Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "pre-network.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "15";
        DynamicUser = "no";
        # ReadOnlyPaths = "/etc/resolv.conf";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
        StateDirectory = "cloudflare-warp";
        RuntimeDirectory = "cloudflare-warp";
        LogsDirectory = "cloudflare-warp";
        ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
      };

      postStart = ''
        while true; do
          set -e
          status=$(${pkgs.cloudflare-warp}/bin/warp-cli status || true)
          set +e

          if [[ "$status" != *"Unable to connect to CloudflareWARP daemon"* ]]; then
            ${pkgs.cloudflare-warp}/bin/warp-cli set-custom-endpoint 162.159.193.1:2408
            exit 0
          fi
          sleep 1
        done
      '';
    };

    tor.wantedBy = lib.mkForce [];
  };

  users.users.cute.packages = [
    (pkgs.writeScriptBin "nyx" ''sudo -u tor -g tor ${inputs.nixpkgs2105.legacyPackages."${pkgs.system}".nyx}/bin/nyx $@'')
    (pkgs.writeScriptBin "tor-warp" ''
      if [[ "$1" == "start" ]]; then
        echo "Starting..."
        warp-cli set-mode proxy
        warp-cli set-proxy-port 4000
        sudo systemctl start tor
      elif [[ "$1" == "stop" ]]; then
        echo "Stopping..."
        warp-cli set-mode warp
        sudo systemctl stop tor
      else
        echo "Error: specify start or stop"
      fi
    '')
  ];

  services.tor = {
    enable = true;
    client = {
      enable = true;
      socksListenAddress = 9050;
    };
    settings = {
      Socks5Proxy = "localhost:4000"; # requires setting warp-svc to proxy mode: warp-cli set-mode proxy && warp-cli set-proxy-port 4000
      ControlPort = 9051;
      CookieAuthentication = true;
    };
  };
}