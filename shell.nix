{ pkgs ? import <nixpkgs> {}}:

pkgs.mkShell {
  description = "shwewo";
  packages = with pkgs; [ gitleaks pre-commit ];
  shellHook = ''
    gitleaks detect -v
    pre-commit install 
  '';
}
