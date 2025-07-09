{ my, ... }:

let
  inherit (builtins)
    attrValues
  ;
  inherit (my.lib)
    getImportableExcept
  ;
in

{
  my.lib.listImportablePathsExcept = dir: except:
    attrValues (getImportableExcept dir except);
}
