{ my, ... }:

let
  inherit (builtins)
    mapAttrs
  ;
  inherit (my.lib)
    getImportableExcept
  ;

  importAllExceptWithScope = dir: except: scope:
    mapAttrs (n: v: scopedImport scope v) (getImportableExcept dir except);

in importAllExceptWithScope
