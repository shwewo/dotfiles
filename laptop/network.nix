{ pkgs, lib, inputs, config, self, USER, stable, unstable, ... }:

let
  shwewo = inputs.shwewo.packages.${pkgs.system};
in {
  imports = [
    (import "${self}/generics/proxy.nix" { 
      inherit pkgs lib inputs stable unstable;
      socksed = [
        { name = "socks-reality-sweden";    script = "sing-box run --config ${config.age.secrets.socks_reality_sweden.path}";                         } # port 2081
        { name = "socks-novpn";             script = "gost -L socks5://192.168.150.2:3535";                                                           } # port 3535
        { name = "socks-spoofdpi";          script = "${shwewo.spoofdpi}/bin/spoof-dpi -addr 192.168.150.2 -port 9999 -dns-addr 1.1.1.1 -debug true"; } # port 9999
        { name = "socks-byedpi";            script = "${shwewo.byedpi}/bin/byedpi -p 10000  --disorder 1 --auto=torst --tlsrec 1+s";                                                          } # port 10000
      ];
    })
  ];

  # systemd.services.socks-usa = {
  #   enable = true;
  #   after = [ "tailscaled.service" ];
  #   wants = [ "tailscaled.service" ];    
  #   wantedBy = [ "multi-user.target" ];

  #   script = ''
  #     autossh -M 0 -N -o "ServerAliveInterval 10" -o "ServerAliveCountMax 3" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i /home/${USER}/.ssh/id_ed25519 -D 127.0.0.1:8888 cute@100.70.203.32
  #   '';

  #   path = with pkgs; [ autossh openssh ];
  # };

  services.openssh = {
    enable = true;
    listenAddresses = [ { addr = "127.0.0.1"; port = 22; } ];
    settings.PasswordAuthentication = false;
  };

  services.tailscale.enable = true;
  # systemd.services.tailscaled.wants = [ "tailserve.service" ];
  systemd.services.tailserve = {
    serviceConfig.Type = "oneshot";
    script = ''
      commands=(
        "tailscale serve --bg --tcp 22 tcp://localhost:22"
      )

      containsSubstring() { [[ $1 == *"$2"* ]]; }
      sleep 5

      for cmd in "''${commands[@]}"; do
        while true; do
          echo "Executing: $cmd"
          if output=$(eval "$cmd" 2>/dev/null); then
            containsSubstring "$output" "Available within your tailnet:" && break || sleep 5
          else
            echo "Error occurred while executing: $cmd"
            sleep 5
          fi
        done
      done
    '';
    path = with pkgs; [ tailscale ];
  };


  systemd.services.yggdrasil.serviceConfig.NetworkNamespacePath = lib.mkForce "/run/netns/novpn_nsd";
  services.yggdrasil = {
    enable = false;
    persistentKeys = true;
      # The NixOS module will generate new keys and a new IPv6 address each time
      # it is started if persistentKeys is not enabled.

    settings = {
      Peers = [
        "tls://yggpeer.tilde.green:59454"
        "tls://de-fsn-1.peer.v4.yggdrasil.chaz6.com:4444"
        "tls://23.137.249.65:444"
        "tcp://cowboy.supergay.network:9111"
        # Yggdrasil will automatically connect and "peer" with other nodes it
        # discovers via link-local multicast announcements. Unless this is the
        # case (it probably isn't) a node needs peers within the existing
        # network that it can tunnel to.
        # "tcp://1.2.3.4:1024"
        # "tcp://1.2.3.5:1024"
        # Public peers can be found at
        # https://github.com/yggdrasil-network/public-peers
      ];
    };
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      server_names = [ "cloudflare" ];
      listen_addresses = [ "127.0.0.1:53" "192.168.150.2:53"];
    };
  };

  systemd.services.dnscrypt-proxy2 = {
    after = [ "novpn.service" "network-online.target" ];
    wants = [ "novpn.service" "network-online.target" ];
    bindsTo = [ "novpn.service" ];

    wantedBy = lib.mkForce [];
    serviceConfig = {
      StateDirectory = "dnscrypt-proxy";
      NetworkNamespacePath = "/run/netns/novpn_nsd";
    };
  };

  systemd.services.novpn = {
    enable = true;
    description = "novpn namespace";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" "dnscrypt-proxy2.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "exec";
    };

    script = ''
      ${inputs.shwewo.packages.${pkgs.system}.namespaced}/bin/namespaced \
       --veth0-ip 192.168.150.1 \
       --veth1-ip 192.168.150.2 \
       --country RU \
       --name novpn \
       --fwmark 0x6e736431 \
       --table 28107
    '';
    
    postStart = ''
      gost -L=tcp://0.0.0.0:4780/192.168.150.2:4780 &>/dev/null &
    '';

    path = with pkgs; [ gost ];
  };
  
  networking = {
    networkmanager = { 
      enable = true;
      dns = "none";
      wifi.macAddress = "stable";
    };
    nameservers = [ "192.168.150.2" ];
    hostName = "laptop";
    hostId = "df3549ee";
    useDHCP = lib.mkDefault true;
    interfaces.wlp1s0.proxyARP = true;
    iproute2.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        # qbittorrent
        4780 
        # audiorelay
        59100
        # localsend
        53317
        # Temp port
        21080
      ];
      allowedUDPPorts = [
        # audiorelay
        59100
        59200
        # localsend 
        53317
        # Temp port
        21080
      ];
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ]; # kde connect
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      checkReversePath = "loose";
      # # No fun allowed
      # extraCommands = ''
      #   iptables -A INPUT -i wlp1s0 -p icmp -j ACCEPT
      #   iptables -A INPUT -i wlp1s0 -m state --state ESTABLISHED,RELATED -j ACCEPT
      #   iptables -A INPUT -i wlp1s0 -j DROP
      # '';
      # extraStopCommands = ''
      #   iptables -D INPUT -i wlp1s0 -p icmp -j ACCEPT
      #   iptables -D INPUT -i wlp1s0 -m state --state ESTABLISHED,RELATED -j ACCEPT
      #   iptables -D INPUT -i wlp1s0 -j DROP
      # '';
    };
  };
  
  systemd.services.NetworkManager-wait-online.enable = false;
}
