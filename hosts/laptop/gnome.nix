{ stable, inputs, config, pkgs, lib, ... }:

let
  wallpaper = pkgs.stdenv.mkDerivation {
    name = "wallpaper";
    installPhase = ''
      mkdir $out
      cp ${../../wallpaper.png} $out/wallpaper.png
    '';
  };
in {
  environment.sessionVariables = { 
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "0";
  };

  nixpkgs.overlays = [
    (final: prev: {
      gnome = prev.gnome.overrideScope' (gnomeFinal: gnomePrev: {
        mutter = gnomePrev.mutter.overrideAttrs (old: {
          src = pkgs.fetchgit {
            url = "https://gitlab.gnome.org/vanvugt/mutter.git";
            # GNOME 45: triple-buffering-v4-45
            rev = "0b896518b2028d9c4d6ea44806d093fd33793689";
            sha256 = "sha256-mzNy5GPlB2qkI2KEAErJQzO//uo8yO0kPQUwvGDwR4w=";
          };
        });

      });
    })
  ];

  # https://discourse.nixos.org/t/need-help-for-nixos-gnome-scaling-settings/24590/12 
  programs.dconf.enable = true;
  programs.dconf.profiles.gdm.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          scaling-factor = lib.gvariant.mkUint32 2;
          };
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
        };
      };
    }
  ];

  programs.dconf.profiles.user.databases = [
    { 
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
        "org/gnome/desktop/interface" = {
          icon-theme = "Papirus-Dark";
        };
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
        };
      };
    }
  ];

  services.xserver = {
    enable = true;
    wacom.enable = true;
    videoDrivers = [ "amdgpu" ];
    displayManager = {
      gdm = {
        enable = true;
        settings = {};
      };
      defaultSession = "gnome";
    };
    desktopManager = {
      gnome = {
        enable = true;
        extraGSettingsOverrides = ''
          [org.gnome.login-screen]
          icon-theme="Papirus-Dark"
          background-picture-uri=${wallpaper}/wallpaper.png
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.activate-window-by-title
    gnomeExtensions.unite
    gnomeExtensions.tailscale-qs
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator
    gnome.gnome-tweaks
    mojave-gtk-theme
    adw-gtk3
    papirus-icon-theme
    # xfce.xfce4-clipman-plugin
    # xfce.xfce4-weather-plugin
    # xfce.xfce4-pulseaudio-plugin
    # xfce.xfce4-xkb-plugin
    # xfce.xfce4-timer-plugin
  ];

  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    epiphany # web browser
    geary # email reader
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    gnome-maps
    gnome-software
    gnome-contacts
    simple-scan
  ]);
}
