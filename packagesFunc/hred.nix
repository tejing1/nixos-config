{ lib, buildNpmPackage, fetchFromGitHub, runCommand, jq }:

buildNpmPackage rec {
  pname = "hred";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "danburzo";
    repo = "hred";
    rev = "v${version}";
    hash = "sha256-+0+WQRI8rdIMbPN0eBUdsWUMWDCxZhTRLiFo1WRd2xc=";
  };

  npmDepsHash = "sha256-kNNvSxZqN6cDZIG+lvqxgjAVCJUJrCvZThxrur5kozU=";

  dontNpmBuild = true;

  meta = {
    description = "A command-line tool to extract data from HTML";
    license = lib.licenses.mit;
    homepage = "https://github.com/danburzo/hred";
    maintainers = with lib.maintainers; [ tejing ];
  };
}
