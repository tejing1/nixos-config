{ my, ... }:
let
  inherit (builtins) filter elem;
  inherit (my.lib) listImportable;
in

dir: except:
# list importable paths in the directory 'dir', except the files named
# in the list of strings 'except'.
filter (n: ! elem n except) (listImportable dir)
