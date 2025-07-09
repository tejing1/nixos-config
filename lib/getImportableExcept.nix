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
in

{
  my.lib.getImportableExcept = dir: except:
    filterAttrs (n: v: !elem n except) (
      getImportable dir
    );
}
