{ config, ... }:

{
  networking = {
    hostName = "ampere-24g";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall = {
      enable = true;
      checkReversePath = "loose";
      allowedTCPPorts = [ 443 ];
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 34812 ];
    openFirewall = false;
    settings.X11Forwarding = true;
  };

  # {"AccountTag":"","TunnelID":"","TunnelSecret":""}
  # echo "token" | base64 --decode
  # replace everything to the correct one
  
  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "default" = {
      default = "http_status:404";
      credentialsFile = "${config.age.secrets.cloudflared.path}";
    };
  };
}
