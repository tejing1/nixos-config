{ my, ... }:

let
  inherit (builtins)
    mapAttrs
  ;
  inherit (my.lib)
    getImportable
  ;

  importAll = dir:
    mapAttrs (n: v: import v) (getImportable dir);

in importAll
