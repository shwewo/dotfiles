{ pkgs, stdenv, fetchFromGitHub }: 

stdenv.mkDerivation {
  pname = "microsocks";
  version = "1.0.4";
  
  src = fetchFromGitHub {
    owner = "rofl0r";
    repo = "microsocks";
    rev = "v1.0.4";
    sha256 = "sha256-cB2XMWjoZ1zLAmAfl/nqjdOyBDKZ+xtlEmqsZxjnFn0=";
  };

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin/
    cp ./microsocks $out/bin/
  '';
}