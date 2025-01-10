{ inputs, pkgs, config, ... }:

{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking = {
    hostName = "ampere-24g";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    iproute2 = {
      enable = true;
      rttablesExtraConfig = "200 enp1s0_table";
    };
    firewall = {
      enable = true;
      checkReversePath = "loose";
      allowedTCPPorts = [ 443 ];
    };
    interfaces.enp0s6 = {
      proxyARP = true;
      ipv4.addresses = [
        {
          address = "10.0.0.187";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = inputs.secrets.hosts.ampere-24g.network.ipv6addr;
          prefixLength = 128;
        }
      ];
    };
    interfaces.enp1s0 = {
      proxyARP = true;
      ipv4.addresses = [
        {
          address = "10.0.0.120";
          prefixLength = 24;
        }
        {
          address = "10.0.0.12";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "10.0.0.1";
      interface = "enp0s6";
    };
    defaultGateway6 = {
      address = "fe80::200:17ff:fece:6c78";
      interface = "enp0s6";
    };
  };

  systemd.services.secondGateway = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    description = "Second gateway";

    script = '' 
      ip route add default via 10.0.0.1 dev enp1s0 src 10.0.0.120 metric 20 || true
      ip route add default via 10.0.0.1 dev enp1s0 src 10.0.0.12 metric 20 || true
      ip rule add from 10.0.0.120/32 table enp1s0_table || true
      ip rule add from 10.0.0.12/32 table enp1s0_table || true
      ip route add default via 10.0.0.1 dev enp1s0 table enp1s0_table || true
    '';

    serviceConfig = {
      Type= "oneshot";
      Restart = "no";
    };

    path = with pkgs; [ bash iproute2 ];
  };

  services.openssh = {
    enable = true;
    ports = [ 34812 ];
    openFirewall = false;
    settings.X11Forwarding = true;
    settings.PasswordAuthentication = false;
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
