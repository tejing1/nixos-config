{
  flake-parts-lib,
  lib,
  my,
  ...
}:

let
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    mkDeferredModuleOption
  ;
  inherit (lib)
    mkOption
    types
  ;
  inherit (types)
    lazyAttrsOf
    attrsOf
    unspecified
  ;
  inherit (my.lib)
    listFlakePartsModules
  ;
in

{
  imports = [
    (mkTransposedPerSystemModule {
      name = "libFor";
      option = mkOption {
        type = attrsOf unspecified;
        default = { };
      };
      file = /. + __curPos.file;
    })
  ];

  options = {
    my.lib = mkOption {
      # Give up attr deletion through priorities/conditions to allow
      # more recursion. Otherwise the module system tries to eval each
      # lib function enough to figure out it isn't a mkIf or mkDefault
      # or whatnot, before it finalizes the set of attribute names
      # under my.lib. If that much evaluation requires something from
      # my.lib, we get infrec.
      type = lazyAttrsOf unspecified;
    };

    perPkgs = mkDeferredModuleOption {
      options.my.lib = mkOption {
        # Give up attr deletion through priorities/conditions to allow
        # more recursion. Otherwise the module system tries to eval each
        # lib function enough to figure out it isn't a mkIf or mkDefault
        # or whatnot, before it finalizes the set of attribute names
        # under my.lib. If that much evaluation requires something from
        # my.lib, we get infrec.
        type = lazyAttrsOf unspecified;
      };
    };
  };

  config = {
    my.flake.modules = listFlakePartsModules ./.;

    perSystem = { my, ... }: {
      libFor = my.using.stable-uncustomized.lib;
    };

    flake = {
      lib = my.lib;
      libFunc = pkgs: (my.using pkgs).lib;
    };
  };
}
