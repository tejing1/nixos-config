{ my, ... }:

{
  flake.homeModules = my.lib.getImportableExcept ./. [ "fpentry" ];
}
