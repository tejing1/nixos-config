{ inputs, lib, ... }:
let
  inherit (builtins) concatMap isAttrs attrValues catAttrs;
  inherit (lib) attrVals;

  # inputs from which to import all nixosModules
  importFrom = [ "self" "home-manager" ];
in

modules: hostname:
{
  imports = modules ++ concatMap (x: if isAttrs x then attrValues x else x) (catAttrs "nixosModules" (attrVals importFrom inputs));
  config._module.args.inputs = inputs;
  config.networking.hostName = hostname;
}
