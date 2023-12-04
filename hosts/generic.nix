{ stable, inputs, config, pkgs, lib, ... }:

{
  users.users.cute = {
    isNormalUser = true;
    description = "cute";
    extraGroups = [ "networkmanager" "wheel" "audio" "libvirtd" "wireshark" "dialout" ];
    initialHashedPassword = "$y$j9T$FfQD9RCuNd.uJOWTuJJQb0$dmh0rfcc5aagT60ebWXgrgmMGfGfBtJ/uDAk3fJLv9/";
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9blPuLoJkCfTl88JKpqnSUmybCm7ci5EgWAUvfEmwb cute@laptop" 
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAZX2ByyBbuOfs6ndbzn/hbLaCAFiMXFsqbjplmx9GfVTx2T1aaDKFRNFtQU1rv6y3jyQCrEbjgvIjdCM4ptDf8=" # ipod
    ];
  };
  boot.kernel.sysctl."kernel.sysrq" = 1;
  i18n.defaultLocale = "en_GB.UTF-8";
  nix.settings.experimental-features = [ "flakes" "nix-command" ];
  nix.settings.auto-optimise-store = true;
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
  services.vnstat.enable = true;
  users.defaultUserShell = pkgs.fish;
  environment.systemPackages = with pkgs; [
    vnstat
    git
    wget
    htop
    any-nix-shell
  ];

  security.wrappers = {
    firejail = {
      source = "${pkgs.firejail.out}/bin/firejail";
    };
  };

  security.rtkit.enable = true;
}
