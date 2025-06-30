{ my, ... }:

let
  inherit (builtins)
    mapAttrs
  ;
  inherit (my.lib)
    getImportable
  ;

  importAllWithArg = dir: arg:
    mapAttrs (n: v: import v arg) (getImportable dir);

in importAllWithArg
