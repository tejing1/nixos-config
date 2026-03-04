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
    listImportablePathsExcept
  ;
in

{
  options = {
    my.overlays = mkOption {
      type = attrsOf (functionTo (functionTo (lazyAttrsOf raw)));
    };
  };

  config = {
    my.flake.modules = listImportablePathsExcept ./. [ "default" ];

    flake.overlays = my.overlays;
  };
}
