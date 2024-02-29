{ stable, inputs, home, config, lib, pkgs, specialArgs, ... }:

{
  home.username = "cute";
  home.stateVersion = "22.11";

  imports = [
    ./apps.nix
    ./scripts.nix
    ./programs.nix
  ];

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };
      "org/gnome/shell/keybindings" = {
        show-screenshot-ui = [ "<Shift><Super>s" ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Alt>Return";
        command = "/etc/profiles/per-user/cute/bin/kitty_wrapped";
        name = "kitty";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Control><Alt>x";
        command = "/etc/profiles/per-user/cute/bin/keepassxc";
        name = "keepassxc";
      };
      "org/gnome/desktop/sound" = {
        allow-volume-above-100-percent = true;
      };
      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = [ "<Shift>Alt_L" ];
        switch-input-source-backward = [ "<Alt>Shift_L" ];
      };
    };
  };
}
