{lib, my, ... }:
with builtins;
with lib;
with my.lib;

dir: except:
# list importable paths in the directory 'dir', except the files named
# in the list of strings 'except'.
map (n: dir + "/${n}") (listImportableExcept dir except)