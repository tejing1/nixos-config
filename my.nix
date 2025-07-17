{
  config,
  flake-parts-lib,
  forPkgs,
  forSystem,
  lib,
  my,
  ...
}:

let
  inherit (builtins)
    mapAttrs
  ;
  inherit (flake-parts-lib)
    mkDeferredModuleOption
    mkPerSystemOption
  ;
  inherit (lib)
    mkOption
    types
    mkMerge
  ;
  inherit (types)
    attrsOf
    unspecified
  ;
in

{
  options = {
    my = {
      using = mkOption {
        type = attrsOf unspecified;
      };
    };
    perPkgs = mkDeferredModuleOption ({
      options.my = {
        using = mkOption {
          type = attrsOf unspecified;
        };
      };
    });
    perSystem = mkPerSystemOption ({
      options.my = {
        using = mkOption {
          type = attrsOf unspecified;
        };
      };
    });
  };

  config = {
    _module.args.my = config.my;
    my.using.__functor = self: pkgs: (forPkgs pkgs).my;

    perPkgs = { config, pkgs, ... }: mkMerge [
      {
        _module.args.my = config.my;
        inherit my;
      }
      {
        my.using = mapAttrs (n: { my, ... }: my) (forSystem pkgs.system).allPkgs;
      }
    ];

    perSystem = { config, ... }: {
      _module.args.my = config.my;
      inherit (config.allPkgs.default) my;
    };
  };
}
