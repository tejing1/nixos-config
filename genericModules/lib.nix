{ config, inputs, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.lib = mkOption {
    type = types.unspecified;
    description = "Library functions from self.lib";
    visible = false;
    readOnly = true;
  };
  config.my.lib = inputs.self.lib.sys."${config.my.system}";
}
