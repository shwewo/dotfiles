<img align="right" src="./logo.png" width="300"/>

![laptop](https://github.com/shwewo/dotfiles/actions/workflows/laptop.yml/badge.svg)
![oracle-cloud](https://github.com/shwewo/dotfiles/actions/workflows/oracle-cloud.yml/badge.svg)

### My NixOS and home-manager configuration
### Note: this configuration is shared "as is", and i highly discourage blindly copy-pasting from it

---

### General structure
- `derivations` - contains some programs that is not included in nixpkgs
- `generics` - generics that usually are hardware-independent
- `laptop` - my daily driver laptop
- `oracle-cloud` - VPS

Note: i'm paranoid, so agenix and some other secrets are outside from this repo in a private one. sorry :3

Also, i don't really like home-manager being outside of the scope of NixOS modules, so i ended up with `./generics/apps.nix` that includes home manager with things that NixOS can't do.

### Desktop

- Gnome shell theme: `Mojave-Dark-solid-alt`
- Cursor theme: `Adwaita`
- Icons: `Papirus-Dark`
- Legacy applications (gtk3): `Adw-gtk3-dark`
- Firefox: [firefox colors theme](https://color.firefox.com/?theme=XQAAAAIcAQAAAAAAAABBKYhm849SCia3ftKEGccwS-xMDPr3mIJS1IAYgPpJmMqoaMV1vHo2YUqSSJyfqfEElOKeefz2PRijvIRDRLIzVMoSNIP805DV03v8JvcdcyT0427oa9ZjoN5H-wSBJomBI-gZyHGhmkB-wbsEkIjDeCMOoz9lf-QAUI6YkJ1vDRwGSSpJC4LwS-wWhw6i88zRfx5YLnkSgJ7JQ0XdiaN7p9mECRTcBSpPrC8AIx_TxFRxSLV-mf75sFj)
<img src="./desktop.png"/>