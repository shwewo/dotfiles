{ pkgs, lib, inputs, config, self, USER, stable, unstable, ... }:

{
  networking = {
    hostName = "twinkcentre";
    hostId = "5eaeb42b";
    useDHCP = lib.mkDefault true;
  #  nameservers = [ "1.1.1.1" "1.0.0.1" ];
    networkmanager.enable = true;
    networkmanager.logLevel = "DEBUG";
   # iproute2.enable = true;
   # firewall = {
   #   enable = true;
   #   checkReversePath = "loose";
   # };
  };

  # systemd.services.NetworkManager-wait-online.enable = false;
}
