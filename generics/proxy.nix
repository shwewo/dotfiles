{ pkgs, lib, inputs, stable, unstable, socksed, ... }:
let
  socksBuilder = attrs:
    {
      inherit (attrs) name;
      value = {
        enable = true;
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = { 
          Restart = "on-failure"; 
          RestartSec = "15"; 
          Type = "simple"; 
          User = "socks"; 
          Group = "socks";
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
        };

        script = attrs.script;
        path = with pkgs; [ 
          iproute2 
          shadowsocks-libev 
          shadowsocks-v2ray-plugin 
          sing-box
          stable.wireproxy
          gost
          unstable.yggstack
          inputs.shwewo.packages.${pkgs.system}.namespaced
          inputs.shwewo.packages.${pkgs.system}.spoofdpi
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
  };

  environment.systemPackages = [
    (pkgs.writeScriptBin "warp-cli" "${pkgs.cloudflare-warp}/bin/warp-cli $@")
  ];
}
