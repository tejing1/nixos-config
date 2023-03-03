{ lib, buildNpmPackage, fetchFromGitHub, runCommand, jq }:

buildNpmPackage rec {
  pname = "hred";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "danburzo";
    repo = "hred";
    rev = "v${version}";
    hash = "sha256-rnobJG9Z1lXEeFm+c0f9OsbiTzxeP3+zut5LYpGzWfc=";
  };

  npmDepsHash = "sha256-POxlGWK0TJMwNWDpiK5+OXLGtAx4lFJO3imoe/h+7Sc=";

  dontNpmBuild = true;

  meta = {
    description = "A command-line tool to extract data from HTML";
    license = lib.licenses.mit;
    homepage = "https://github.com/danburzo/hred";
    maintainers = with lib.maintainers; [ tejing ];
  };
}
