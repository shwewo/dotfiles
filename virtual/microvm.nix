{ pkgs, lib, inputs, self, config, ... }:

{
  imports = [
    inputs.microvm.nixosModules.host
  ];
  
  microvm.vms.proxybox = {
    autostart = false;

    config = import "${self}/virtual/proxybox.nix" { 
      inherit pkgs lib inputs self config; 
      nixpkgs.config.allowUnfree = true; 
    } // { imports = [ inputs.impermanence.nixosModules.impermanence ]; };
  };

  systemd.services."microvm@proxybox" = {
    wantedBy = lib.mkForce [];

    serviceConfig = {
      NetworkNamespacePath = "/run/netns/novpn_nsd";
    };
  };
  
  systemd.services.gost-proxybox = {
    enable = false;
    description = "gost";
    wantedBy = [ "multi-user.target" ];
    after = [ "pre-network.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "15";
      DynamicUser = "yes";
      ExecStart = "${pkgs.gost}/bin/gost -L tcp://:3050/192.168.150.2:3050 -L tcp://:9050/192.168.150.2:9050";
    };  
  };
}
