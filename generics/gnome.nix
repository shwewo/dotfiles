{ pkgs, lib, inputs, ... }: with lib.gvariant;

let
  wallpaper = pkgs.stdenv.mkDerivation {
    name = "wallpaper";
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/share/backgrounds
      cp ${../wallpaper.png} $out/share/backgrounds/wallpaper.png
    '';
  };
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # home-manager.users.cute.home.pointerCursor = {
  #   gtk.enable = true;  
  #   x11.enable = true;
  #   package = pkgs.gnome.adwaita-icon-theme;
  #   name = "Adwaita";
  #   size = 24;
  # };

  environment.sessionVariables = { 
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "0";
    # XCURSOR_SIZE = "24";
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
          scaling-factor = mkUint32 2;
        };
      };
    }
  ];

  programs.dconf.profiles.user.databases = [
    { 
      settings = {
        # "org/gnome/mutter" = {
        #   experimental-features = [ "scale-monitor-framebuffer" ];
        # };
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
          # close = mkEmptyAy (type.string);
          switch-input-source = [ "<Shift>Alt_L" ];
          switch-input-source-backward = [ "<Alt>Shift_L" ];
        };
        "org/gnome/desktop/interface" = {
          icon-theme = "Papirus-Dark";
          color-scheme = "prefer-dark";
          gtk-theme = "adw-gtk3-dark";
        };
        "org/gnome/shell" = {
          favorite-apps = [
            "firefox.desktop" 
            "vesktop.desktop"
            "org.telegram.desktop.desktop" 
            "spotify.desktop" 
            "kitty.desktop" 
            "org.gnome.Nautilus.desktop"
          ];
          disable-user-extensions = false;
          enabled-extensions = [
            "activate-window-by-title@lucaswerkmeister.de" "appindicatorsupport@rgcjonas.gmail.com" "clipboard-indicator@tudmotu.com" 
            "gsconnect@andyholmes.github.io"
            "tailscale@joaophi.github.com"
            "unite@hardpixel.eu" 
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "pip-on-top@rafostar.github.com"
            "cloudflare-warp-toggle@khaled.is-a.dev"
          ];
        };
        "org/gnome/desktop/input-sources" = {
          mru-sources = [ (mkTuple [ "xkb" "us" ]) ];
          sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "xkb" "ru" ]) ];
          xkb-options = [ "terminate:ctrl_alt_bksp" "lv3:switch" "compose:ralt" ];
        };
        "org/gnome/desktop/screensaver" = {
          lock-enabled = false;
        };
        "org/gnome/desktop/notifications" = {
          show-in-lock-screen = false;
        };
        "org/gnome/desktop/session" = {
          idle-delay = mkUint32 0;
        };
        "org/gnome/shell/extensions/unite" = {
          enable-titlebar-actions = true; 
          extend-left-box = false;
          hide-activities-button = "never";
          hide-app-menu-icon = false;
          notifications-position = "center";
          reduce-panel-spacing = true;
          restrict-to-primary-screen = false;
          show-appmenu-button = true;
          show-desktop-name = false;
          show-legacy-tray = false;
          show-window-buttons = "never";
          show-window-title = "never";
        };
        "org/gnome/shell/extensions/user-theme" = {
          name = "Mojave-Dark-solid-alt";
        };
        "org/gnome/shell/weather" = {
          automatic-location = true;
        };
        "org/gnome/desktop/background" = {
          picture-uri = "file:///run/current-system/sw/share/backgrounds/wallpaper.png";
          picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/wallpaper.png";
        };
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
        };
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
        };
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.activate-window-by-title
    gnomeExtensions.unite
    gnomeExtensions.tailscale-qs
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.pip-on-top
    gnomeExtensions.cloudflare-warp-toggle
    gnome.gnome-tweaks
    mojave-gtk-theme
    adw-gtk3
    papirus-icon-theme
    wallpaper
  ];

  environment.gnome.excludePackages = (with pkgs.gnome; [ 
    pkgs.gnome-tour
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
