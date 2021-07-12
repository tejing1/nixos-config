{ my, ... }:
let
  inherit (my.lib) listImportableExcept;
in

dir: except:
# list importable paths in the directory 'dir', except the files named
# in the list of strings 'except'.
map (n: dir + "/${n}") (listImportableExcept dir except)
