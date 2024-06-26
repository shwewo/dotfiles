{ pkgs, lib, self, inputs, modulesPath, ... }:

{
  imports = [
    inputs.nixos-shell.nixosModules.nixos-shell
    "${self}/generics/default.nix"
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  time.timeZone = "Europe/Amsterdam";
  networking.hostName = "ephemeral";
  networking.networkmanager.enable = true;

  users.users.virtual = {
    isNormalUser = true;
    description = "virtual";
    extraGroups = [ "networkmanager" "wheel" "audio" "libvirtd" "wireshark" "dialout" "plugdev" "adbusers" ];
    initialHashedPassword = "";
  };

  nixos-shell.mounts = {
    mountHome = false;
    mountNixProfile = false;
    cache = "none"; # default is "loose"
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  environment.variables = {
    QEMU_OPTS = "-m 4096 -smp 4 -enable-kvm";
  };

  environment.systemPackages = with pkgs; [
    distrobox
  ];

  virtualisation.memorySize = 8192;
  virtualisation.cores = 3;
  virtualisation.diskSize = 4 * 1024;

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
  boot.tmp.cleanOnBoot = true;

  system.stateVersion = "21.05"; # Did you read the comment?
}