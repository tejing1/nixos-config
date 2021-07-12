{ lib, my, ... }:
let
  inherit (lib) nixosSystem;
  inherit (my.lib) mkDefaultNixosModule;
in

modules: system: hostname:
let
  configurationModule = mkDefaultNixosModule modules hostname;
in
{ inherit configurationModule; } //
nixosSystem {
  inherit system;
  modules = [ configurationModule ];
}
