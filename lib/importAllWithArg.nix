{ lib, my, ... }:
with builtins;
with lib;
with my.lib;

dir: arg:
# import every importable path in the directory 'dir', passing
# argument 'arg', returns an attrset of the import results named by
# the files (without the .nix suffix) or directories they came from.
listToAttrs (map (n: nameValuePair (removeSuffix ".nix" n) (import (dir + "/${n}") arg)) (listImportable dir))
