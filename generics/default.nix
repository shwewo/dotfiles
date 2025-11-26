{ pkgs, inputs, user, ... }:
{
  imports = [
    ./htoprc.nix
  ];

  users.users.${user} = {
    isNormalUser = true;
    description = user;
    extraGroups = [ "networkmanager" "wheel" "audio" "libvirtd" "wireshark" "dialout" "plugdev" "adbusers" "lxd" "docker" "files" "incus-admin" ];
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9blPuLoJkCfTl88JKpqnSUmybCm7ci5EgWAUvfEmwb" 
    ];
    initialHashedPassword = "$y$j9T$ahTzaJgMed8v7tJvsiZWf0$z.zckWQ0ApVHxC1ErvvIz3.7cgc8OZWwTzQrtyMOC34";
  };

  nix = {
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      auto-optimise-store = true;
      substituters = [
        "https://shwewo.cachix.org"
      ];
      trusted-public-keys = [
        "shwewo.cachix.org-1:84cIX7ETlqQwAWHBnd51cD4BeUVXCyGbFdtp+vLxKOo="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  boot.kernel.sysctl."kernel.sysrq" = 1;
  boot.tmp.cleanOnBoot = true;
  i18n.defaultLocale = "en_GB.UTF-8";

  programs = {
    firejail.enable = true;
    command-not-found.enable = false;
    direnv.enable = true;
    direnv.silent = true;
    tmux.enable = true;
    fish = {
      enable = true;
      shellAliases = {
        ls = "${pkgs.lsd}/bin/lsd";
        rebuild = ''nh os switch -- --option warn-dirty false'';
        ssh = "TERM=xterm-256color /run/current-system/sw/bin/ssh";
      };
      promptInit = ''
        set TERM "xterm-256color"
        set fish_greeting
        set fish_color_command blue
      '';
    };
  };

  services.vnstat.enable = true;
  users.defaultUserShell = pkgs.fish;

  environment.sessionVariables.NH_OS_FLAKE = "/home/${user}/Documents/dotfiles";
  environment.systemPackages = with pkgs; [
    # Network
    dnsutils
    inetutils
    iw
    iperf3
    mtr
    wirelesstools
    wireguard-tools
    nmap
    wget
    wget
    vnstat
    tshark
    tcpdump
    dig
    # Administration
    usbutils
    pciutils
    nh
    neofetch
    util-linux
    htop
    killall
    nix-search-cli
    nix-index
    lm_sensors
    lsof
    # Files
    imagemagick
    ncdu
    ffmpeg
    p7zip
    rclone
    unzip
    zip
    tree
    # Utilities
    micro
    git
    lua5_4
    python3
    # Fish shell
    fd
    sysz
    grc
    bat
    # fishPlugins.done
    fishPlugins.grc
    fishPlugins.autopair
    # fishPlugins.z
    fishPlugins.fzf-fish
    # fishPlugins.sponge
    iosevka
    # Misc
    (pkgs.fzf.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall + ''
        # Remove shell integrations
        rm -rf $out/share/fzf $out/share/fish $out/bin/fzf-share
      '' + (builtins.replaceStrings
        [
          ''
            # Install shell integrations
            install -D shell/* -t $out/share/fzf/
            install -D shell/key-bindings.fish $out/share/fish/vendor_functions.d/fzf_key_bindings.fish
            mkdir -p $out/share/fish/vendor_conf.d
            cat << EOF > $out/share/fish/vendor_conf.d/load-fzf-key-bindings.fish
              status is-interactive; or exit 0
              fzf_key_bindings
            EOF
          ''
        ]
        [""]
        oldAttrs.postInstall);
    }))
    (pkgs.writeScriptBin "haste" "HASTE_SERVER=https://haste.eww.workers.dev ${pkgs.haste-client}/bin/haste $@")
  ];

  security.wrappers = {
    firejail = {
      source = "${pkgs.firejail.out}/bin/firejail";
    };
  };

  security.rtkit.enable = true;
}