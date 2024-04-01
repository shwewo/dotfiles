{ self, config, lib, pkgs, ... }:

{
  imports = [
    "${self}/generics/default.nix"
    ./hardware.nix
    ./xorg.nix
  ];

  networking.hostName = "nixosvm"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/Amsterdam";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.pulseaudio.enable = false;

  system.stateVersion = "23.11"; # Did you read the comment?
}