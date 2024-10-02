{ inputs, pkgs, config, ... }:

{
  users.groups.no-net = {};
  networking = {
    hostName = "oracle-cloud";
    nat.enable = true;
    nat.externalInterface = "enp0s3";
    nameservers = [ "1.1.1.1" "1.1.0.1" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        443
      ];
      extraCommands = ''
        iptables -A OUTPUT -m owner --gid-owner no-net -j REJECT
      '';
      checkReversePath = "loose";
    };
  };

  services.openssh = {
    enable = true;
    extraConfig = '' 
      ClientAliveInterval 500
      ClientAliveCountMax 50
      LoginGraceTime 0 
    '';
    settings = {
      X11Forwarding = true;
      Macs = [
        "hmac-sha2-256"
        "hmac-sha2-512"
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com" 
      ];
    };
    ports = [ 34812 ];
  };

  # {"AccountTag":"","TunnelID":"","TunnelSecret":""}
  # echo "token" | base64 --decode
  # replace everything to the correct one
  
  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "unified" = {
      default = "http_status:404";
      credentialsFile = "${config.age.secrets.cloudflared.path}";
    };
  };

  environment.systemPackages = with pkgs; [ cloudflare-warp ];

  systemd.services.warp-svc = {
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

  services.tailscale.enable = true;
}
