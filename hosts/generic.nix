{ stable, inputs, config, pkgs, lib, ... }:

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
    extraGroups = [ "networkmanager" "wheel" "audio" "libvirtd" "wireshark" "dialout" "plugdev" ];
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
    registry.sys.flake = inputs.nixpkgs;
  };

  boot.kernel.sysctl."kernel.sysrq" = 1;
  i18n.defaultLocale = "en_GB.UTF-8";
  nixpkgs.config.allowUnfree = true;
  programs.firejail.enable = true;
  programs.command-not-found.enable = false;
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
    rollback = "sudo nixos-rebuild switch --rollback --flake ~/dev/dotfiles/";
  };
  services.vnstat.enable = true;
  users.defaultUserShell = pkgs.fish;
  environment.systemPackages = with pkgs; [
    run
    vnstat
    git
    wget
    htop
    any-nix-shell
    ncdu
    btop
    nix-output-monitor
    inputs.nh.packages.${pkgs.system}.default
  ];
  environment.sessionVariables.FLAKE = "/home/cute/dev/dotfiles";

  security.wrappers = {
    firejail = {
      source = "${pkgs.firejail.out}/bin/firejail";
    };
  };

  security.rtkit.enable = true;
}
