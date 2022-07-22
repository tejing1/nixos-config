{ config, inputs, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.lib = mkOption {
    type = types.unspecified;
    description = "Library functions from self";
    visible = false;
    readOnly = true;
  };
  config.my.lib = inputs.self.libFunc pkgs;
}
