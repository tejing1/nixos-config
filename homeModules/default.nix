{ my, ... }:

{
  flake.homeModules = my.lib.getImportableExcept ./. [ "default" ];
}
