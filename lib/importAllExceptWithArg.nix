{ lib, my, ... }:
let
  inherit (builtins) listToAttrs;
  inherit (lib) nameValuePair removeSuffix;
  inherit (my.lib) listImportableExcept;
in

dir: except: arg:
# import every importable path in the directory 'dir', passing
# argument 'arg', except files named in the list of strings 'except'.
# returns an attrset of the import results named by the files (without
# the .nix suffix) or directories they came from.
listToAttrs (map (n: nameValuePair (removeSuffix ".nix" n) (import (dir + "/${n}") arg)) (listImportableExcept dir except))
