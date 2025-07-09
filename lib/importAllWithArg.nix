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
  my.lib.importAllWithArg = dir: arg:
    mapAttrs (n: v: import v arg) (getImportable dir);
}
