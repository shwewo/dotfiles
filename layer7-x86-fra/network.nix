{ inputs, ... }: 
{ 
  networking = {
    hostName = "layer7-x86-fra";
    nftables.enable = true;

    nameservers = [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::fe" ];

    firewall = {
      enable = true;
      trustedInterfaces = [ "incusbr0" ];
      allowedTCPPorts = [ 1234 ];
    };

    interfaces.eth0 = {
      macAddress = "16:a0:39:c3:b0:eb";
      ipv4.addresses = [ 
        { address = inputs.secrets.hosts.layer7-x86-fra.network.ipv4addr; prefixLength = 24; } 
      ];
      ipv6.addresses = [ 
        { address = inputs.secrets.hosts.layer7-x86-fra.network.ipv6addr; prefixLength = 48; } 
      ];
    };

    defaultGateway = {
      address = inputs.secrets.hosts.layer7-x86-fra.network.gateway4;
      interface = "eth0";
    };

    defaultGateway6 = {
      address = inputs.secrets.hosts.layer7-x86-fra.network.gateway6;
      interface = "eth0";
    };
  };
}