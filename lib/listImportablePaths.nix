{lib, my, ... }:
with builtins;
with lib;
with my.lib;

dir:
# list importable paths in the directory 'dir',
map (n: dir + "/${n}") (listImportable dir)
