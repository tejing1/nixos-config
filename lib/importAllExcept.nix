{ my, ... }:

let
  inherit (builtins)
    mapAttrs
  ;
  inherit (my.lib)
    getImportableExcept
  ;

  importAllExcept = dir: except:
    mapAttrs (n: v: import v) (getImportableExcept dir except);

in importAllExcept
