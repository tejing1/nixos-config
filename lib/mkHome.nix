{ lib, my, inputs, ... }:
with builtins;
with lib;
with my.lib;
with inputs.home-manager.lib;

modules: system: username:
let
  configurationModule = mkDefaultHomeModule modules username;
in
{ inherit configurationModule; } //
homeManagerConfiguration {
  inherit system username;
  homeDirectory = "/home/${username}";
  configuration = configurationModule;
}
