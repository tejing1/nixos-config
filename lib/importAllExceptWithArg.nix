{ my, ... }:

let
  inherit (builtins)
    mapAttrs
  ;
  inherit (my.lib)
    getImportableExcept
  ;

  importAllExceptWithArg = dir: except: arg:
    mapAttrs (n: v: import v arg) (getImportableExcept dir except);

in importAllExceptWithArg
