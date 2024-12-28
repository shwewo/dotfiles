{ pkgs, lib, inputs, unstable, USER, ... }: with lib.gvariant;

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

  environment.sessionVariables = { 
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  services.gnome.gnome-remote-desktop.enable = true;

  nixpkgs.overlays = [
    # GNOME 46: triple-buffering-v4-46
    (final: prev: {
      gnome = prev.gnome.overrideScope (gnomeFinal: gnomePrev: {
        mutter = gnomePrev.mutter.overrideAttrs ( old: {
          src = pkgs.fetchgit {
            url = "https://gitlab.gnome.org/vanvugt/mutter.git";
			      rev = "663f19bc02c1b4e3d1a67b4ad72d644f9b9d6970";
            sha256 = "sha256-I1s4yz5JEWJY65g+dgprchwZuPGP9djgYXrMMxDQGrs=";         
          };
        } );
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
          command = "/etc/profiles/per-user/${USER}/bin/kitty_wrapped";
          name = "kitty";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          binding = "<Control><Alt>x";
          command = "/etc/profiles/per-user/${USER}/bin/keepassxc";
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
            "activate-window-by-title@lucaswerkmeister.de" 
            "gsconnect@andyholmes.github.io"
            "unite@hardpixel.eu" 
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "pip-on-top@rafostar.github.com"
            "cloudflare-warp-toggle@khaled.is-a.dev"
            "pano@elhan.io"
            "always-indicator@martin.zurowietz.de"
            "overviewbackground@github.com.orbitcorrection"
            "hide-keyboard-layout@sitnik.ru"
          ];
        };

        "org/gnome/desktop/input-sources" = {
          mru-sources = [ (mkTuple [ "xkb" "us" ]) ];
          sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "xkb" "ru" ]) ];
          xkb-options = [ "terminate:ctrl_alt_bksp" "lv3:switch" "compose:ralt" ];
        };

        "org/gnome/desktop/screensaver" = {
          lock-enabled = true;
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
          hide-app-menu-icon = true;
          notifications-position = "center";
          reduce-panel-spacing = true;
          restrict-to-primary-screen = false;
          show-appmenu-button = true;
          show-desktop-name = false;
          show-legacy-tray = false;
          show-window-buttons = "never";
          show-window-title = "never";
        };

        "org/gnome/shell/extensions/pano" = {
          active-item-border-color = "rgb(222,221,218)";
          history-length = mkDouble 500;
          hovered-item-border-color = "rgb(255,255,255)";
          is-in-incognito = false;
          item-size = mkUint32 200;
          play-audio-on-copy = false;
          send-notification-on-copy = false;
          show-indicator = false;
          wiggle-indicator = false;
          window-position = mkUint32 0;
          link-previews = false;
        };
        
        "org/gnome/shell/extensions/pano/color-item" = {
          header-bg-color = "rgb(61,56,70)";
          metadata-bg-color = "rgb(61,56,70)";
        };

        "org/gnome/shell/extensions/pano/emoji-item" = {
          body-bg-color = "rgb(61,56,70)";
          header-bg-color = "rgb(51,209,122)";
        };

        "org/gnome/shell/extensions/pano/file-item" = {
          body-bg-color = "rgb(61,56,70)";
          body-color = "rgb(222,221,218)";
          header-bg-color = "rgb(152,106,68)";
        };

        "org/gnome/shell/extensions/pano/image-item" = {
          header-bg-color = "rgb(53,132,228)";
        };

        "org/gnome/shell/extensions/pano/link-item" = {
          body-bg-color = "rgb(61,56,70)";
          header-bg-color = "rgb(145,65,172)";
        };

        "org/gnome/shell/extensions/pano/text-item" = {
          body-bg-color = "rgb(61,56,70)";
          body-color = "rgb(222,221,218)";
          char-length = mkUint32 650;
          header-bg-color = "rgb(53,132,228)";
        };

        "org/gnome/shell/extensions/always-indicator" = {
          color = "rgb(222,221,218)";
        };

        "org/gnome/shell/extensions/user-theme" = {
          name = "Mojave-Dark-solid";
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
    (gnomeExtensions.unite.overrideAttrs (oldAttrs: {
      src = pkgs.fetchFromGitHub {
        owner = "hardpixel";
        repo = "unite-shell";
        rev = "master";
        hash = "sha256-OyxNibjQn7VBEdAPUaGd0MEgzCzpaFqViMKhF52haUI=";
      };
    }))
    gnomeExtensions.gsconnect
    gnomeExtensions.hide-keyboard-layout
    gnomeExtensions.always-indicator
    gnomeExtensions.overview-background
    gnome-sound-recorder
    gnome-tweaks
    nautilus
    file-roller
    gsound
    libgda6
    adw-gtk3
    unstable.papirus-icon-theme
    wallpaper
  ];
}
