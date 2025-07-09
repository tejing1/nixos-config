{ my, ... }:

let
  inherit (builtins)
    attrValues
  ;
  inherit (my.lib)
    getImportable
  ;
in

{
  my.lib.listImportablePaths = dir:
    attrValues (getImportable dir);
}
