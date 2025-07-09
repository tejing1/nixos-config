{ my, ... }:

{
  flake.nixosModules = my.lib.getImportableExcept ./. [ "default" ];
}
