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
    all
    filter
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

  # Type modifier which only allows definitions coming from the specified file
  onlyfromfile = file: type: type // {
    merge = loc: defs:
      if all (def: def.file == file) defs then
        type.merge loc defs
      else
        throw ''
          The option ${lib.options.showOption loc} was set from a different file than the allowed one (${file}).
          Offending definition values:${lib.options.showDefs (filter (def: def.file != file) defs)}
        '';
  };
in

{
  options = {
    my = {
      using = mkOption {
        type = attrsOf unspecified;
      };
    };
    perPkgs = mkDeferredModuleOption {
      options.my = mkOption {
        type = types.submodule {
          freeformType = onlyfromfile "${__curPos.file}, via option perPkgs" unspecified;
          options.using = mkOption {
            type = attrsOf unspecified;
          };
        };
      };
    };
    perSystem = mkPerSystemOption {
      options.my = mkOption {
        type = types.submodule {
          freeformType = onlyfromfile "${__curPos.file}, via option perSystem" unspecified;
          options.using = mkOption {
            type = attrsOf unspecified;
          };
        };
      };
    };
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
        my.using = mapAttrs (n: { my, ... }: my) (forSystem pkgs.stdenv.hostPlatform.system).allPkgs;
      }
    ];

    perSystem = { config, ... }: {
      _module.args.my = config.my;
      inherit (config.allPkgs.default) my;
    };
  };
}
