{ my, ... }:

let
  inherit (builtins)
    mapAttrs
  ;
  inherit (my.lib)
    getImportable
  ;
in

{
  my.lib.importAll = dir:
    mapAttrs (n: v: import v) (getImportable dir);
}
