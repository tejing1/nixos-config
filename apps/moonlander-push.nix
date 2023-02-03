{ system, self, nixpkgs, ... }:
let
  inherit (nixpkgs.legacyPackages.${system}) wally-cli writeShellScript;
  firmware = self.packages.${system}.moonlander-firmware;
in
{
  type = "app";
  program = "${writeShellScript "moonlander-push" ''
    sudo ${wally-cli}/bin/wally-cli ${firmware}
  ''}";
}
