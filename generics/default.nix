{ pkgs, inputs, unstable, USER, ... }:
{
  users.users.${USER} = {
    isNormalUser = true;
    description = USER;
    extraGroups = [ "networkmanager" "wheel" "audio" "libvirtd" "wireshark" "dialout" "plugdev" "adbusers" ];
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9blPuLoJkCfTl88JKpqnSUmybCm7ci5EgWAUvfEmwb" 
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAZX2ByyBbuOfs6ndbzn/hbLaCAFiMXFsqbjplmx9GfVTx2T1aaDKFRNFtQU1rv6y3jyQCrEbjgvIjdCM4ptDf8=" # ipod
    ];
    initialHashedPassword = "";
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

  programs.firejail.enable = true;
  programs.command-not-found.enable = false;
  programs.direnv.enable = true;
  programs.direnv.silent = true;
  programs.tmux.enable = true;
  programs.fish.enable = true;
  programs.fish.promptInit = ''
    set TERM "xterm-256color"
    set fish_greeting
    any-nix-shell fish --info-right | source
  '';
  programs.fish.shellAliases = {
    ls = "${pkgs.lsd}/bin/lsd";
    search = "nix-search -d -m 5 -p";
    reboot = ''read -P "Do you REALLY want to reboot? (y/N) " answer; and string match -q -r '^[Yy]' $answer; and ${pkgs.systemd}/bin/reboot'';
    rebuild = ''nh os switch -- --option warn-dirty false'';
    rollback = ''sudo nixos-rebuild switch --rollback --flake ~/dev/dotfiles/'';
  };

  services.vnstat.enable = true;
  users.defaultUserShell = pkgs.fish;

  environment.sessionVariables.FLAKE = "/home/${USER}/dev/dotfiles";
  environment.systemPackages = with pkgs; [
    # Network
    dnsutils
    inetutils
    iw
    wirelesstools
    wireguard-tools
    nmap
    wget
    wget
    vnstat
    tshark
    tcpdump
    # Administration
    usbutils
    pciutils
    unstable.nh
    neofetch
    util-linux
    htop
    killall
    unstable.nix-search-cli
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
    # Fish shell
    any-nix-shell
    fd
    sysz
    grc
    bat
    fishPlugins.done
    fishPlugins.grc
    fishPlugins.autopair
    fishPlugins.z
    fishPlugins.fzf-fish
    fishPlugins.sponge
    (nerdfonts.override { fonts = [ "Iosevka" ]; })    
    # Misc
    (pkgs.writeScriptBin "haste" "HASTE_SERVER=https://haste.eww.workers.dev ${pkgs.haste-client}/bin/haste $@")
    (pkgs.writeScriptBin "rollback" "")
    (pkgs.writeScriptBin "shell" ''
      #!/usr/bin/env bash
      packages=""
      for package in "$@"; do
        packages+="nixpkgs#$package "
      done
      packages=$(echo "$packages" | xargs)

      NIXPKGS_ALLOW_UNFREE=1 .any-nix-wrapper fish --impure $packages
    '')
    (pkgs.writeScriptBin "run" ''NIXPKGS_ALLOW_UNFREE=1 nix run --impure nixpkgs#"$1" -- "''${@:2}"'')
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
  ];

  security.wrappers = {
    firejail = {
      source = "${pkgs.firejail.out}/bin/firejail";
    };
  };
  security.rtkit.enable = true;
  
  environment.etc."htoprc".text = ''
    config_reader_min_version=3
    fields=0 48 46 47 49 1
    hide_kernel_threads=1
    hide_userland_threads=1
    hide_running_in_container=0
    shadow_other_users=0
    show_thread_names=0
    show_program_path=0
    highlight_base_name=1
    highlight_deleted_exe=1
    shadow_distribution_path_prefix=0
    highlight_megabytes=1
    highlight_threads=1
    highlight_changes=0
    highlight_changes_delay_secs=5
    find_comm_in_cmdline=1
    strip_exe_from_cmdline=1
    show_merged_command=0
    header_margin=1
    screen_tabs=1
    detailed_cpu_time=0
    cpu_count_from_one=0
    show_cpu_usage=1
    show_cpu_frequency=1
    show_cpu_temperature=1
    degree_fahrenheit=0
    update_process_names=0
    account_guest_in_cpu_meter=0
    color_scheme=6
    enable_mouse=1
    delay=15
    hide_function_bar=1
    header_layout=two_50_50
    column_meters_0=LeftCPUs Memory Swap
    column_meter_modes_0=2 2 2
    column_meters_1=RightCPUs Tasks LoadAverage Uptime
    column_meter_modes_1=2 2 2 2
    tree_view=0
    sort_key=46
    tree_sort_key=0
    sort_direction=-1
    tree_sort_direction=1
    tree_view_always_by_pid=0
    all_branches_collapsed=0
    screen:Main=PID USER PERCENT_CPU PERCENT_MEM TIME Command
    .sort_key=PERCENT_CPU
    .tree_sort_key=PID
    .tree_view_always_by_pid=0
    .tree_view=0
    .sort_direction=-1
    .tree_sort_direction=1
    .all_branches_collapsed=0
    screen:I/O=PID USER IO_PRIORITY IO_RATE IO_READ_RATE IO_WRITE_RATE PERCENT_SWAP_DELAY PERCENT_IO_DELAY Command
    .sort_key=PID
    .tree_sort_key=PID
    .tree_view_always_by_pid=0
    .tree_view=0
    .sort_direction=1
    .tree_sort_direction=1
    .all_branches_collapsed=0
  '';
}