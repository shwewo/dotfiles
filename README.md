<img align="right" src="./logo.png" width="300"/>

### My NixOS and home-manager configuration
### Note: this configuration is shared "as is", and i highly discourage blindly copy-pasting from it

---

### General structure
- `derivations` - contains some programs that is not included in nixpkgs
- `generics` - generics that usually are hardware-independent
- `laptop` - my daily driver laptop
- `oracle-cloud` - VPS

Note: i'm paranoid, so agenix and some other secrets are outside from this repo in a private one. sorry :3

---

Also, i don't really like home-manager being outside of the scope of NixOS modules, so i ended up with `./generics/apps.nix` that includes home manager with things that NixOS can't do.