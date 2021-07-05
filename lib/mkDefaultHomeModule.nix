{ lib, my, inputs, ... }:
with builtins;
with lib;
with my.lib;

let
  # inputs from which to import all homeModules
  importFrom = [ "self" ];
in

modules: username:
{
  imports = modules ++ concatMap (x: if isAttrs x then attrValues x else x) (catAttrs "homeModules" (attrVals importFrom inputs));
  config._module.args.inputs = inputs;
  config.home.username = mkDefault username;
  config.home.homeDirectory = mkDefault "/home/${username}";
}
