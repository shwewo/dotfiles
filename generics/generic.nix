{ pkgs, inputs, ... }:

let
  run = pkgs.writeScriptBin "run" ''
    #!/usr/bin/env bash
    if [[ $# -eq 0 ]]; then
      echo "Error: Missing argument"
    else
      NIXPKGS_ALLOW_UNFREE=1 nix run --impure nixpkgs#"$1" -- "''\${@:2}"
    fi
  '';
in {
  users.users.cute = {
    isNormalUser = true;
    description = "cute";
    extraGroups = [ "networkmanager" "wheel" "audio" "libvirtd" "wireshark" "dialout" "plugdev" "adbusers" ];
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9blPuLoJkCfTl88JKpqnSUmybCm7ci5EgWAUvfEmwb cute@laptop" 
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAZX2ByyBbuOfs6ndbzn/hbLaCAFiMXFsqbjplmx9GfVTx2T1aaDKFRNFtQU1rv6y3jyQCrEbjgvIjdCM4ptDf8=" # ipod
    ];
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

  boot.kernel.sysctl."kernel.sysrq" = 1;
  boot.tmp.cleanOnBoot = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  nixpkgs.config.allowUnfree = true;

  programs.firejail.enable = true;
  programs.command-not-found.enable = false;
  programs.direnv.enable = true;
  programs.direnv.silent = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
  };
  programs.tmux.enable = true;
  programs.fish.enable = true;
  programs.fish.promptInit = ''
    set TERM "xterm-256color"
    set fish_greeting
    any-nix-shell fish --info-right | source
  '';
  programs.fish.shellAliases = {
    rebuild = "nh os switch -- --option warn-dirty false";
    haste = "HASTE_SERVER=https://haste.eww.workers.dev ${pkgs.haste-client}/bin/haste";
    rollback = "sudo nixos-rebuild switch --rollback --flake ~/dev/dotfiles/";
  };

  services.vnstat.enable = true;
  users.defaultUserShell = pkgs.fish;

  environment.sessionVariables.FLAKE = "/home/cute/dev/dotfiles";
  environment.systemPackages = with pkgs; [
    run
    vnstat
    htop
    tree
    tshark
    git
    wget
    any-nix-shell
    ncdu
    fishPlugins.done
    inputs.nh.packages.${pkgs.system}.default
    (pkgs.writeScriptBin "reboot" ''read -p "Do you REALLY want to reboot? (y/N) " answer; [[ $answer == [Yy]* ]] && ${pkgs.systemd}/bin/reboot'')
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