<img align="right" src="./logo.png" width="300"/>

### My NixOS and home-manager configuration
### Note: this configuration is shared "as is", and i highly discourage blindly copy-pasting from it

---

### General structure
- `derivations` contains some programs that is not included in nixpkgs
- `home` is my home-manager configuration
- `hosts` hosts-specific configurations
- `modules` hosts-specific modules that can be disabled safely
- `secrets` self-explainatory

### Home structure
- `apps.nix` only for home.packages
- `cute.nix` is an entry point for all home-manager
- `programs.nix` is for `programs.<name>` things only
- `scripts.nix` scripts that were brought to existence for some reason

### Host structure
- `laptop` my current daily-driver, contains systemd-wide and critical hardware configuration
- `oracle-cloud` my oracle-cloud arm instance
- `generic.nix` is my "core" utilities that i use and not included in home-manager, and it has to be installed on all hosts, so it should be agnostic to architecture/host hardware
  
### Modules structure
- `laptop` contains some non-critical services for laptop (?)
- `oracle-cloud` same as for laptop