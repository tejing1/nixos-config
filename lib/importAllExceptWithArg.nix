{ my, ... }:

let
  inherit (builtins)
    mapAttrs
  ;
  inherit (my.lib)
    getImportableExcept
  ;
in

{
  my.lib.importAllExceptWithArg = dir: except: arg:
    mapAttrs (n: v: import v arg) (getImportableExcept dir except);
}
