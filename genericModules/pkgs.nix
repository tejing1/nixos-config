{ inputs, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.pkgs = mkOption {
    type = types.unspecified;
    description = "Packages from self";
    visible = false;
    readOnly = true;
  };
  config.my.pkgs = inputs.self.packagesFunc pkgs;
}
