{ pkgs, lib, inputs, stable, unstable, socksed, ... }:
let
  nixpkgs2305 = import inputs.nixpkgs2305 { system = "${pkgs.system}"; config = { allowUnfree = true; }; };
  socksBuilder = attrs:
    {
      inherit (attrs) name;
      value = {
        enable = true;
        after = [ "novpn.service" "network-online.target" ];
        wants = [ "novpn.service" "network-online.target" ];
        bindsTo = [ "novpn.service" ];

        serviceConfig = { 
          Restart = "on-failure"; 
          RestartSec = "15"; 
          Type = "simple"; 
          User = "socks"; 
          Group = "socks";
          RuntimeMaxSec=3600;
          NetworkNamespacePath = "/run/netns/novpn_nsd";
        };

        script = attrs.script;
        path = with pkgs; [ 
          iproute2 
          shadowsocks-libev 
          shadowsocks-v2ray-plugin 
          unstable.sing-box 
          stable.wireproxy
          unstable.gost
        ];
      };
    };
in {
  users.users.socks = {
    group = "socks";
    isSystemUser = true;
  };

  users.groups.socks = {};
  systemd.services = builtins.listToAttrs (map socksBuilder socksed) // { 
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
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
        StateDirectory = "cloudflare-warp";
        RuntimeDirectory = "cloudflare-warp";
        LogsDirectory = "cloudflare-warp";
        ExecStart = "${nixpkgs2305.cloudflare-warp}/bin/warp-svc";
        LogLevelMax = 3;
      };

      # To register, connect to a VPN
      # Then run: warp-cli set-custom-endpoint 162.159.193.1:2408
    };

    tor.wantedBy = lib.mkForce [];
    novpn.wants = map (s: "${s.name}.service") socksed;
  };

  environment.systemPackages = [
    (pkgs.writeScriptBin "warp-cli" "${nixpkgs2305.cloudflare-warp}/bin/warp-cli $@")
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
      # UseBridges = true;
      # ClientTransportPlugin = "snowflake exec ${pkgs.snowflake}/bin/client";
      # Bridge = "snowflake 192.0.2.3:80 2B280B23E1107BB62ABFC40DDCC8824814F80A72 fingerprint=2B280B23E1107BB62ABFC40DDCC8824814F80A72 url=https://snowflake-broker.torproject.net.global.prod.fastly.net/ fronts=www.shazam.com,www.cosmopolitan.com,www.esquire.com ice=stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 utls-imitate=hellorandomizedalpn";
      Socks5Proxy = "localhost:4000"; # requires setting warp-svc to proxy mode: warp-cli set-mode proxy && warp-cli set-proxy-port 4000
      ControlPort = 9051;
      CookieAuthentication = true;
    };
  };
}