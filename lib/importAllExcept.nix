{ lib, my, ... }:
with builtins;
with lib;
with my.lib;

dir: except:
# import every importable path in the directory 'dir', except files
# named in the list of strings 'except'.  returns an attrset of the
# import results named by the files (without the .nix suffix) or
# directories they came from.
listToAttrs (map (n: nameValuePair (removeSuffix ".nix" n) (import (dir + "/${n}"))) (listImportableExcept dir except))
