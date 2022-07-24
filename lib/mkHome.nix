{ inputs, my, ... }:
let
  inherit (my.lib) mkDefaultHomeModule;
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
in

modules: system: username:
let
  configurationModule = mkDefaultHomeModule modules username;
in
{ inherit configurationModule; } //
homeManagerConfiguration {
  inherit system username;
  homeDirectory = "/home/${username}";
  configuration = configurationModule;
  extraSpecialArgs = { inherit inputs; };
}
