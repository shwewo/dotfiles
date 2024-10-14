{ config, inputs, lib, pkgs, modulesPath, ... }: 

{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  boot = {
    initrd.kernelModules = [ "efi_pstore" "efivarfs" "tpm_crb" "tpm_tis" ];
    kernelParams = [ "rd.systemd.gpt_auto=0" ];
    initrd.systemd.emergencyAccess = false;
    loader.systemd-boot.enable = lib.mkForce false;
    bootspec.enable = true;

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    initrd.systemd = {
      enable = true;
      enableTpm2 = true;
      additionalUpstreamUnits = [ "systemd-tpm2-setup-early.service" ];
      storePaths = [
        "${config.boot.initrd.systemd.package}/lib/systemd/systemd-tpm2-setup"
        "${config.boot.initrd.systemd.package}/lib/systemd/system-generators/systemd-tpm2-generator"
      ];
    };
  };

  systemd.enableEmergencyMode = false;
  
  environment.systemPackages = with pkgs; [ 
    sbctl 
    tpm2-tools
    tpm2-tss
  ];
}