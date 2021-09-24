{ lib, nixosConfig, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.system = mkOption {
    type = types.unspecified;
    description = "The system type we're building for";
    visible = false;
    readOnly = true;
  };
  config.my.system = nixosConfig.nixpkgs.system;
}
