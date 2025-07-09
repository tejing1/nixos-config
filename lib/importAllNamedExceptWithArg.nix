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
  my.lib.importAllNamedExceptWithArg = dir: except: arg:
    mapAttrs (n: v: import v arg n) (getImportableExcept dir except);
}
