{ inputs, lib, my, ... }:

let
  inherit (builtins)
    isPath
  ;
  inherit (lib)
    mkOption
    types
  ;
  inherit (my.lib)
    listFlakePartsModules
  ;
in

{
  options = {
    my.flake.root = mkOption {
      type = types.addCheck types.path isPath;
    };
  };

  config = {
    my.flake.root = ./.;
    my.flake.modules = listFlakePartsModules ./.;
  };
}
