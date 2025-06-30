{ my, ... }:

let
  inherit (builtins)
    attrValues
  ;
  inherit (my.lib)
    getImportable
  ;

  listImportablePaths = dir:
    attrValues (getImportable dir);

in listImportablePaths
