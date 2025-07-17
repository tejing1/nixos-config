{
  flake-parts-lib,
  lib,
  my,
  mylib,
  ...
}:

let
  inherit (flake-parts-lib)
    mkDeferredModuleOption
    mkPerSystemOption
  ;
  inherit (lib)
    mkOption
    types
  ;
  inherit (types)
    attrsOf
    functionTo
    lazyAttrsOf
    unspecified
    unique
  ;
in

{
  imports = mylib.listImportablePathsExcept ./. [ "default" ];

  options = {
    my.overlays = mkOption {
      type = attrsOf (functionTo (functionTo (lazyAttrsOf unspecified)));
    };

    perPkgs = mkDeferredModuleOption {
      options.my.overlays = mkOption {
        type = unique { message = "Don't set 'perPkgs.my.overlays'. Set 'my.overlays' instead.";} unspecified;
      };
    };

    perSystem = mkPerSystemOption {
      options.my.overlays = mkOption {
        type = unique { message = "Don't set 'perSystem.my.overlays'. Set 'my.overlays' instead.";} unspecified;
      };
    };
  };

  config = {
    flake.overlays = my.overlays;
  };
}
