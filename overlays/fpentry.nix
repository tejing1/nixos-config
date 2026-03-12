{
  lib,
  my,
  ...
}:

let
  inherit (lib)
    mkOption
    types
  ;
  inherit (types)
    attrsOf
    functionTo
    lazyAttrsOf
    raw
  ;
  inherit (my.lib)
    listFlakePartsModules
  ;
in

{
  options = {
    my.overlays = mkOption {
      type = attrsOf (functionTo (functionTo (lazyAttrsOf raw)));
    };
  };

  config = {
    my.flake.modules = listFlakePartsModules ./.;

    flake.overlays = my.overlays;
  };
}
