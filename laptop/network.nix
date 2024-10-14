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
      ];
    })
  ];

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
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;

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
  };

  systemd.services.yggdrasil.serviceConfig.NetworkNamespacePath = lib.mkForce "/run/netns/yggdrasil_nsd";
  systemd.services.yggdrasil.after = [ "yggdrasil-nsd.service" "run-netns-yggdrasil_nsd.mount" ];
  systemd.services.yggdrasil.wants = [ "yggdrasil-nsd.service" "run-netns-yggdrasil_nsd.mount" ];
  systemd.services.yggdrasil.bindsTo = [ "yggdrasil-nsd.service" ];
  
  services.yggdrasil = {
    enable = true;
    persistentKeys = true;
    settings = {
      Peers = [
        "tls://yggpeer.tilde.green:59454"
        "tls://de-fsn-1.peer.v4.yggdrasil.chaz6.com:4444"
        "tls://23.137.249.65:444"
        "tcp://cowboy.supergay.network:9111"
        "quic://x-mow-0.sergeysedoy97.ru:65535"
        "tcp://x-mow-0.sergeysedoy97.ru:65533"
        "quic://srv.itrus.su:7993"
        "tls://srv.itrus.su:7992"
        # https://github.com/yggdrasil-network/public-peers
      ];
    };
  };

  systemd.services.yggdrasil-nsd = {
    enable = true;
    description = "yggdrasil namespace";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" "yggdrasil.service" "yggdrasil-forward.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "exec";
    };

    script = ''
      ${inputs.shwewo.packages.${pkgs.system}.namespaced}/bin/namespaced \
        --veth0-ip 192.168.84.1 \
        --veth1-ip 192.168.84.2 \
        --name yggdrasil \
        --fwmark 0x6e735432 \
        --table 28113
    '';
  };

  systemd.services.yggdrasil-forward = {
    enable = true;
    description = "yggdrasil forward";
    after = [ "yggdrasil-nsd.service" "run-netns-yggdrasil_nsd.mount" ];
    wants = [ "yggdrasil-nsd.service" "run-netns-yggdrasil_nsd.mount" ];
    bindsTo = [ "yggdrasil-nsd.service" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "simple";
      ExecStart = "${pkgs.gost}/bin/gost -L=socks5://192.168.84.2:3535";
      NetworkNamespacePath = "/run/netns/yggdrasil_nsd";
      DynamicUser = true;
    };
  };
}
