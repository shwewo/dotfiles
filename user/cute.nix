{ pkgs, lib, inputs, config, self, stable, unstable, rolling, USER, ... }:

let
  misc = import ./misc.nix { inherit inputs pkgs lib config self stable unstable rolling USER; };
  overrides = import ./overrides.nix { inherit inputs pkgs lib config self stable unstable rolling USER; };
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  shwewo = inputs.shwewo.packages.${pkgs.system};
in {
  imports = [
    ./home.nix
    ./patchdesktop.nix
    inputs.spicetify-nix.nixosModules.default
  ]; 

  users.users.${USER}.packages = (with pkgs; [
    # Browsers
    ungoogled-chromium
    google-chrome
    shwewo.ephemeralbrowser
    overrides.tor-browser
    # FilesLAND
    # overrides.dropbox
    # overrides.dropbox-cli
    maestral
    maestral-gui
    gocryptfs
    rolling.localsend
    inotify-tools
    misc.cloudsync
    misc.fitsync
    # Network
    nekoray
    socat
    gost # gost -L redirect://:3333 -F socks5://192.168.150.2:3333 trans proxy (UDP doesn't work)
    wireproxy
    networkmanagerapplet
    trayscale
    cloudflared
    iodine
    ptunnel
    remmina
    shwewo.namespaced
    overrides.lnxrouter
    # Messengers
    element-desktop
    rolling.ayugram-desktop
    overrides.vesktop
    # Administration
    mission-center
    libnotify
    virt-manager
    virt-viewer
    misc.windows
    # Utilities
    inputs.agenix.packages.${pkgs.system}.default
    misc.virt
    appimage-run
    rolling.scrcpy
    tldr
    zenity
    distrobox
    libreoffice
    translate-shell
    torsocks
    wl-clipboard
    overrides.autostart
    overrides.obsidian
    overrides.kitty_wrapped
    # Games
    protonup-qt
    lutris
    #inputs.yuzu-nixpkgs.legacyPackages.${pkgs.system}.yuzu-mainline
    prismlauncher
    # Audio
    stable.spotdl
    pavucontrol
    shwewo.audiorelay
    # Video
    rolling.yt-dlp
    kooha
    celluloid
    overrides.obs
    jamesdsp # audio compressor
    easyeffects
    # Graphics
    gromit-mpx
    krita
    inkscape
    drawing
    flameshot
    gcolor3
    # Secrets
    overrides.keepassxc
    yubioath-flutter
    # Misc
    monero-gui
    steamcmd
    # openjfx11
    # openjdk11
    zulu11 # java
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    jq # needed for kitty
  ]);

  # security.wrappers.nekoray_core = {
  #   source = "${pkgs.nekoray}/bin/nekoray_core";
  #   owner = "root";
  #   group = "root";
  #   capabilities = "cap_net_admin,cap_net_raw=ep";
  #   permissions = "u+rx,g+x";
  # };

  programs = {
    gamemode.enable = true;
    gamescope.enable = true;
    adb.enable = true;
    firejail.enable = true;
    noisetorch.enable = true;
    spicetify = {
      enable = true;
      theme = spicePkgs.themes.spotifyNoPremium;

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
      ];
      
      spotifyPackage = pkgs.spotify.overrideAttrs (
        old: {
          postInstall =
            (old.postInstall or "")
            + ''
              sed -i "s|Exec=spotify %U|Exec=${pkgs.writeScriptBin "open" ''
                if ! pgrep "spotify" > /dev/null; then
                  spotify &

                  while ! dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
                    /org/mpris/MediaPlayer2 \
                    org.mpris.MediaPlayer2.Player.Play > /dev/null 2>&1; do
                    sleep 1
                  done
                fi

                dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.spotify \
                  /org/mpris/MediaPlayer2 \
                  org.mpris.MediaPlayer2.Player.OpenUri \
                  string:"$1"
              ''}/bin/open %U|" "$out/share/applications/spotify.desktop"
            '';
        }
      );
    };
    steam = {
      enable = true;
      package = pkgs.steam.override (old: {
        extraBwrapArgs = [
          "--setenv SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt"
          "--setenv SSL_CERT_DIR ${pkgs.cacert.unbundled}/etc/ssl/certs"
        ];
      });
    };
    wireshark = { 
      enable = true;
      package = pkgs.wireshark; 
    };
  };
}
