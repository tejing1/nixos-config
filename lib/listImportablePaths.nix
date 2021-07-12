{ my, ... }:
let
  inherit (my.lib) listImportable;
in

dir:
# list importable paths in the directory 'dir',
map (n: dir + "/${n}") (listImportable dir)
