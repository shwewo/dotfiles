{ pkgs, lib, inputs, unstable, socksed, ... }:
let
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
          unstable.wireproxy
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
        ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
        LogLevelMax = 3;
      };

      # To register, connect to a VPN
      # Then run: warp-cli set-custom-endpoint 162.159.193.1:2408
    };

    tor.wantedBy = lib.mkForce [];
    novpn.wants = map (s: "${s.name}.service") socksed;
  };

  environment.systemPackages = [
    (pkgs.writeScriptBin "warp-cli" "${pkgs.cloudflare-warp}/bin/warp-cli $@")
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