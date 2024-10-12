{ pkgs, lib, inputs, config, self, USER, stable, unstable, ... }:

{
  networking = {
    hostName = "twinkcentre";
    hostId = "5eaeb42b";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
    iproute2.enable = true;
    firewall = {
      enable = true;
      checkReversePath = "loose";
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;
}