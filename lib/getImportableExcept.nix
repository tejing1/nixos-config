{ lib, my, ... }:

let
  inherit (builtins)
    elem
  ;
  inherit (lib)
    filterAttrs
  ;
  inherit (my.lib)
    getImportable
  ;

  getImportableExcept = dir: except:
    filterAttrs (n: v: !elem n except) (
      getImportable dir
    );

in getImportableExcept
