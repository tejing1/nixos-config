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
  my.lib.importAllExcept = dir: except:
    mapAttrs (n: v: import v) (getImportableExcept dir except);
}
