{ stable, inputs, home, config, lib, pkgs, specialArgs, ... }:

{
  home.username = "cute";
  home.stateVersion = "22.11";

  imports = [
    ./scripts.nix
    ./programs.nix
    ./apps.nix
  ];

  xdg.desktopEntries = {
    keepassxc = {
      name = "KeePassXC";
      icon = "keepassxc";
      exec = ''sh -c "cat /run/agenix/precise | ${pkgs.keepassxc}/bin/keepassxc --pw-stdin ~/Dropbox/Sync/passwords.kdbx"'';
      type = "Application";
    };
    ephemeralbrowser = {
      name = "Ephemeral Browser";
      icon = "google-chrome-unstable";
      exec = "ephemeralbrowser";
      type = "Application";
    };
    autostart = {
      name = "autostart";
      icon = "settings";
      exec = "/home/cute/.autostart.sh";
      type = "Application";
    };
  };

  home.file."autostart" = {
    enable = true;
    target = "/.autostart.sh";
    executable = true;
    text = ''
      #!/bin/sh
      sleep 5
      gtk-launch maestral.desktop
      gtk-launch keepassxc.desktop
      gtk-launch vesktop.desktop
      gtk-launch org.telegram.desktop.desktop
      gtk-launch spotify.desktop
      gtk-launch firefox.desktop
    '';
  };

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };
}
