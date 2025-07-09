{ mylib, ... }:

{
  imports = mylib.listImportablePathsExcept ./. [ "default" ];
}
