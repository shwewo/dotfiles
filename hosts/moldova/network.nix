{ stable, inputs, config, pkgs, lib, ... }: {
  services.openssh = {
    enable = true;
    extraConfig = '' 
      ClientAliveInterval 500
      ClientAliveCountMax 50 
    '';
    #ports = [ 34812 ];
  };

  networking = {
    hostName = "moldova";
    usePredictableInterfaceNames = true;
    firewall.checkReversePath = "loose";
    interfaces.eth0.ipv4.addresses = [ {
      address = inputs.meow.hosts.moldova.network.ip;
      prefixLength = 24;
    } ];
    defaultGateway = inputs.meow.hosts.moldova.network.gateway;
    nameservers = [ "1.1.1.1" ];
      firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 23 ];
      allowedUDPPorts = [ 53 ];
    };
  };
  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "unified" = {
      default = "http_status:404";
      credentialsFile = "/run/agenix/cloudflared";
    };
  };
}