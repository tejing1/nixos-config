{ my, ... }:

{
  flake.nixosModules = my.lib.getImportableExcept ./. [ "fpentry" ];
}
