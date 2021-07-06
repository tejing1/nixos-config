{ nixosConfig, lib, ... }:
with builtins;
with lib;
{
  options.my.system = mkOption {
    type = types.unspecified;
    description = "The system type we're building for";
    visible = false;
    readOnly = true;
  };
  config.my.system = nixosConfig.nixpkgs.system;
}
