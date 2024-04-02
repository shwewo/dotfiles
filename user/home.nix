{ pkgs, inputs, unstable, USER, ... }:
let
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${USER} = {
    home.username = "${USER}";
    home.stateVersion = "23.11";

    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        DisplayBookmarksToolbar = "never";
        DNSOverHTTPS = {
          Enabled = false;
          ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
          Locked = false;
        };
        
        Preferences = {
          "ui.key.menuAccessKeyFocuses" = lock-false;
          "signon.generation.enabled" = lock-false;
          "browser.compactmode.show" = lock-true;
          "browser.uidensity" = { Value = 1; Status = "locked"; };
          # "mousewheel.with_alt.action" = { Value = "-1"; Status = "Locked"; }; # Not allowed for stability reason; do manually
          "browser.tabs.firefox-view" = lock-false;
          # "full-screen-api.ignore-widgets" = lock-true; # Not allowed for stability reason; do manually
        };

        # https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/17
        # about:debugging#/runtime/this-firefox
        ExtensionSettings = with builtins;
          let extension = shortId: uuid: {
            name = uuid;
            value = {
              install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
              installation_mode = "normal_installed";
            };
          };
          in listToAttrs [
            (extension "ublock-origin" "uBlock0@raymondhill.net")
            (extension "container-proxy" "contaner-proxy@bekh-ivanov.me")
            (extension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}")
            (extension "darkreader" "addon@darkreader.org")
            (extension "firefox-color" "FirefoxColor@mozilla.com")
            (extension "multi-account-containers" "@testpilot-containers")
            (extension "jkcs" "{6d9f4f04-2499-4fed-ae4a-02c5658c5d00}")
            (extension "keepassxc-browser" "keepassxc-browser@keepassxc.org")
            (extension "new-window-without-toolbar" "new-window-without-toolbar@tkrkt.com")
            (extension "open-in-spotify-desktop" "{04a727ec-f366-4f19-84bc-14b41af73e4d}")
            (extension "search_by_image" "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}")
            (extension "single-file" "{531906d3-e22f-4a6c-a102-8057b88a1a63}")
            (extension "soundfixer" "soundfixer@unrelenting.technology")
            (extension "sponsorblock" "sponsorBlocker@ajay.app")
            (extension "tampermonkey" "firefox@tampermonkey.net")
            (extension "torrent-control" "{e6e36c9a-8323-446c-b720-a176017e38ff}")
            (extension "unpaywall" "{f209234a-76f0-4735-9920-eb62507a54cd}")
            (extension "ctrl-number-to-switch-tabs" "{84601290-bec9-494a-b11c-1baa897a9683}")
            (extension "temporary-containers" "{c607c8df-14a7-4f28-894f-29e8722976af}")
            (extension "tree-style-tab" "treestyletab@piro.sakura.ne.jp")
          ];
      };
    };

    programs.fish = {
      enable = true;
      shellAliases = {
        fru = "trans ru:en";
        fen = "trans en:ru";
        icat = "kitten icat";
      };
      shellInit = ''
        set -U __done_kitty_remote_control 1
        set -U __done_kitty_remote_control_password "kitty-notification-password-fish"
        set -U __done_notification_command "${pkgs.libnotify}/bin/notify-send --icon=kitty --app-name=kitty --wait \$title \$argv[1] > /dev/null 2>&1 &"
        set -U __done_notification_urgency_level_failure critical
      '';
    };

    programs.vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        matklad.rust-analyzer
        jnoortheen.nix-ide
      ];
      enableUpdateCheck = false;
      userSettings = {
        "window.titleBarStyle" = "custom";
        "nix.enableLanguageServer"= true;
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
        "nix.serverSettings" = {
          nil = {
            formatting = {
              command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
            };
          };
        };
      };
    };
  
    programs.git = {
      enable = true;
      userName  = "shwewo";
      userEmail = "shwewo@gmail.com";
    };

    programs.ssh = {
      enable = true;
      matchBlocks = {
        "debian" = {
          hostname = "192.168.122.222"; 
        };
        "oracle-cloud" = {
          hostname = inputs.secrets.hosts.oracle-cloud.network.ip;
          port = inputs.secrets.hosts.oracle-cloud.network.ssh.port;
        };
        "sn1" = {
          hostname = inputs.secrets.hosts.sn1.network.ip;
          port = inputs.secrets.hosts.sn1.network.ssh.port;
        };
        "canada" = {
          hostname = inputs.secrets.hosts.canada.network.ip;
          port = inputs.secrets.hosts.canada.network.ssh.port;
        };
        "finland" = {
          hostname = inputs.secrets.hosts.finland.network.ip;
          port = inputs.secrets.hosts.finland.network.ssh.port;
        };
        "france" = {
          hostname = inputs.secrets.hosts.france.network.ip;
          port = inputs.secrets.hosts.france.network.ssh.port;
        };
        "nyadesk" = {
          hostname = "192.168.50.150";
        };
        "nyalapt" = {
          hostname = "192.168.50.219";
          port = 55755;
        };
      };
    };

    programs.kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = false;
      settings = {
        background = "#171717";
        foreground = "#DCDCCC";
        background_opacity = "0.8";
        remember_window_size = "yes";
        hide_window_decorations = "yes";
        remote_control_password = "kitty-notification-password-fish ls";
        allow_remote_control = "password";

        color0 = "#3F3F3F";
        color1 = "#705050";
        color2 = "#60B48A";
        color3 = "#DFAF8F";
        color4 = "#9AB8D7";
        color5 = "#DC8CC3";
        color6 = "#8CD0D3";
        color7 = "#DCDCCC";

        color8 = "#709080";
        color9 = "#DCA3A3";
        color10 = "#72D5A3";
        color11 = "#F0DFAF";
        color12 = "#94BFF3";
        color13 = "#EC93D3";
        color14 = "#93E0E3";
        color15 = "#FFFFFF";
      };
    };

    programs.mpv = { 
      enable = true;
      config = {
        hwdec = "auto";
        slang = "en,eng";
        alang = "en,eng";
        subs-fallback = "default";
        subs-with-matching-audio = "yes";
        save-position-on-quit = "yes";
      };
      scripts = with pkgs; [ 
        mpvScripts.autoload
      ];
      scriptOpts = {
        autoload = {
          disabled = "no";
          images = "no";
          videos = "yes";
          audio = "yes";
          additional_image_exts = "list,of,ext";
          additional_video_exts = "list,of,ext";
          additional_audio_exts = "list,of,ext";
          ignore_hidden = "yes";
        };
      };
    };
  };
}