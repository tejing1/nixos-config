{ lib, my, ... }:
with builtins;
with lib;
with my.lib;

dir: except: arg:
# import every importable path in the directory 'dir', passing its
# name after another argument 'arg', except files named in the list of
# strings 'except'.  returns an attrset of the import results named by
# the files (without the .nix suffix) or directories they came from.
listToAttrs (map (n: nameValuePair (removeSuffix ".nix" n) (import (dir + "/${n}") arg (removeSuffix ".nix" n))) (listImportableExcept dir except))
