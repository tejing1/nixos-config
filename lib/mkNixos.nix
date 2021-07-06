{ lib, my, ... }:
with builtins;
with lib;
with my.lib;

modules: system: hostname:
let
  configurationModule = mkDefaultNixosModule modules hostname;
in
{ inherit configurationModule; } //
nixosSystem {
  inherit system;
  modules = [ configurationModule ];
}
