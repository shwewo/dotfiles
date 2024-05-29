{ pkgs, lib, inputs, config, self, stable, unstable, USER, ... }:

let
  misc = import ./misc.nix {
    inherit inputs pkgs lib config self stable unstable USER;
    rclonepass = config.age.secrets.rclone.path;
    backuppass = config.age.secrets.backup.path;
  };
  overrides = import ./overrides.nix {
    inherit inputs pkgs lib config self stable unstable USER;
    dbpass = config.age.secrets.precise.path;
  };
  shwewo = inputs.shwewo.packages.${pkgs.system};
in {
  imports = [
    ./home.nix
    ./patchdesktop.nix
  ];

  users.users.${USER}.packages = (with pkgs; [
    # Browsers
    ungoogled-chromium
    shwewo.ruchrome
    shwewo.ephemeralbrowser
    # FilesLAND
    # overrides.dropbox
    # overrides.dropbox-cli
    maestral
    maestral-gui
    gocryptfs
    unstable.localsend
    inotify-tools
    misc.cloudsync
    misc.fitsync
    # Network
    gost # gost -L redirect://:3333 -F socks5://192.168.150.2:3333 trans proxy (UDP doesn't work)
    wireproxy
    networkmanagerapplet
    trayscale
    iodine
    ptunnel
    remmina
    shwewo.namespaced
    overrides.lnxrouter
    # Messengers
    element-desktop
    shwewo.tdesktop
    overrides.vesktop
    # Administration
    mission-center
    stable.libnotify
    virt-manager
    virt-viewer
    misc.windows
    # Utilities
    inputs.agenix.packages.${pkgs.system}.default
    misc.virt
    appimage-run
    scrcpy
    tldr
    gnome.zenity
    distrobox
    libreoffice
    translate-shell
    overrides.autostart
    overrides.obsidian
    overrides.kitty_wrapped
    # Games
    protonup-qt
    lutris
    #inputs.yuzu-nixpkgs.legacyPackages.${pkgs.system}.yuzu-mainline
    prismlauncher
    # Audio
    shwewo.spotify
    stable.spotdl
    pavucontrol
    shwewo.audiorelay
    # Video
    yt-dlp
    celluloid
    overrides.obs
    # Graphics
    gromit-mpx
    krita
    inkscape
    drawing
    flameshot
    # Secrets
    overrides.keepassxc
    stable.yubioath-flutter
    yubikey-manager-qt
    # Misc
    monero-gui
    # openjfx11
    # openjdk11
    zulu11 # java
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    jq # needed for kitty
  ]);

  programs = {
    wireshark = { enable = true; package = stable.wireshark; };
    gamemode.enable = true;
    gamescope.enable = true;
    steam = {
      enable = true;
      package = pkgs.steam.override {
        # withGameSpecificLibraries = false;
        extraLibraries = pkgs: with pkgs; [
          zstd
          libxml2
          libdeflate
          libmd
          lz4
          icu
          libgcrypt
          libgpg-error
          libasyncns
        ];
      };
    };
    adb.enable = true;
    firejail.enable = true;
  };
}
