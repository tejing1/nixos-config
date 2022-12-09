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
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  modules = [
    configurationModule
    {
      home.username = username;
      home.homeDirectory = "/home/${username}";
    }
  ];
  extraSpecialArgs = { inherit inputs; };
}
