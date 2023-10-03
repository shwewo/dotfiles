{ stable, inputs, config, pkgs, lib, ... }:

{
  networking = {
    hostName = "oracle-cloud";
    nat.enable = true;
    nat.externalInterface = "enp0s3";
    nameservers = [ "1.1.1.1" "1.1.0.1" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 4040 23 ];
      allowedUDPPorts = [ 61385 53 4500 500 ];
      checkReversePath = "loose";
    };
  };

  services.openssh = {
    enable = true;
    extraConfig = '' 
      ClientAliveInterval 500
      ClientAliveCountMax 50 
    '';
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