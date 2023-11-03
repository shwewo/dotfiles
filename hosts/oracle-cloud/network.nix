{ stable, inputs, config, pkgs, lib, ... }:

{
  networking = {
    hostName = "oracle-cloud";
    nat.enable = true;
    nat.externalInterface = "enp0s3";
    nameservers = [ "1.1.1.1" "1.1.0.1" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        443
        8080
        # mediamtx (hls, rtsp, webrtc, rtmp)
        8554 
        8000 
        8001 
        1935 
        8888 
        8889 
        8890 
      ];
      allowedUDPPorts = [ 
        # mediamtx (hls, rtsp, webrtc, rtmp)
        8554 
        8000 
        8001 
        1935 
        8888 
        8889 
        8890 
        # ipsec
        4500
        500
      ];
      allowedUDPPortRanges = [ 
        { from = 52000; to = 52100; } 
      ];
      checkReversePath = "loose";
    };
  };

  services.openssh = {
    enable = true;
    extraConfig = '' 
      ClientAliveInterval 500
      ClientAliveCountMax 50 
    '';
    settings.X11Forwarding = true;
    ports = [ 34812 ];
  };
  
  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "unified" = {
      default = "http_status:404";
      credentialsFile = "/run/agenix/cloudflared";
    };
  };
  services.tailscale.enable = true;
}
