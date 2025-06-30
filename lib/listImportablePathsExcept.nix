{ my, ... }:

let
  inherit (builtins)
    attrValues
  ;
  inherit (my.lib)
    getImportableExcept
  ;

  listImportablePathsExcept = dir: except:
    attrValues (getImportableExcept dir except);

in listImportablePathsExcept
