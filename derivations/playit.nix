{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "playit-agent";
  version = "v0.9.3";
  doCheck = false;

  src = fetchFromGitHub {
    owner = "playit-cloud";
    repo = pname;
    rev = version;
    sha256 = "sha256-iiz+zRAXp7qsoLHLwMPolXSCX6CT1oV+X8cFyVEppoY=";
  };

  cargoSha256 = "sha256-nuv3UTeHgIvbPdulpRQXLlwytHB44aCWqwMRH+dS1uo=";

  meta = with lib; {
    description = "game client to run servers without portforwarding";
    homepage = "https://github.com/playit-cloud/playit-agent";
    license = licenses.unlicense;
    maintainers = [ "Yeshey" ];
  };
}
