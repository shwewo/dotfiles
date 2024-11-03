{ pkgs, lib, inputs, config, self, USER, stable, unstable, ... }:

let
  novpnSocksConfig = {
    after = [ "novpn.service" ];
    wants = [ "novpn.service" ];
    bindsTo = [ "novpn.service" ];
    serviceConfig.NetworkNamespacePath = "/var/run/netns/novpn_nsd";
  };
in {
  imports = [
    (import "${self}/generics/proxy.nix" { 
      inherit pkgs lib inputs stable unstable;
      socksed = [
        { name = "socks-reality-sweden";    script = "sing-box run --config ${config.age.secrets.socks_reality_sweden.path}";                                                              } # port 2081
        { name = "socks-novpn";             script = "gost -L socks5://192.168.150.2:3535";                                                                                                } # port 3535
        { name = "socks-spoofdpi";          script = "spoof-dpi -addr 192.168.150.2 -port 9999 -dns-addr 1.1.1.1 -debug true";                                                             } # port 9999
        { name = "yggstack";                script = "yggstack -useconffile /etc/yggdrasil/yggdrasil.conf -socks 127.0.0.1:5050 -local-tcp 127.0.0.1:3333:[324:71e:281a:9ed3::fa11]:1080"; } # port 5050, clearnet 3333
      ];
    })
  ];

  systemd.services.socks-novpn = novpnSocksConfig;
  systemd.services.socks-reality-sweden = novpnSocksConfig;
  systemd.services.socks-spoofdpi = novpnSocksConfig;

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
    wants = [ "network-online.target" "dnscrypt-proxy2.service" "socks-novpn.service" "socks-reality-sweden.service" "socks-spoofdpi.service" ];
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
        --table 28107 \
        --nokill \
        --dontcreate
    '';

    preStart = ''
      ${pkgs.iproute2}/bin/ip netns add novpn_nsd
    '';
    postStop = ''
      ${pkgs.iproute2}/bin/ip netns del novpn_nsd 
    '';
  };
}
