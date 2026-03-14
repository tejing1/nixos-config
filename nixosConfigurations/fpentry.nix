{ my, ... }:

{
  my.flake.modules = my.lib.listFlakePartsModules ./.;
}
