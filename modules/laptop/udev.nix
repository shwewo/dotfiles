{ stable, inputs, config, pkgs, lib, ... }:
 
{
  services.udev.packages = with pkgs; [ yubikey-personalization android-udev-rules ];
  services.udev.extraRules = ''
    # USB-Blaster
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6002", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6003", MODE="0666", GROUP="plugdev"

    # USB-Blaster II
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6010", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6810", MODE="0666", GROUP="plugdev"
  '';
}
