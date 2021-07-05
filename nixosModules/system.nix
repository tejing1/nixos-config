{ config, lib, ... }:
with lib;
{
  options.my.system = mkOption {
    type = types.unspecified;
    description = "The system type we're building for";
    visible = false;
    readOnly = true;
  };
  config.my.system = config.nixpkgs.system;
}
