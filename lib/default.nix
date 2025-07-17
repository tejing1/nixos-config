{
  flake-parts-lib,
  lib,
  my,
  mylib,
  pre-eval,
  ...
}:

# In order for mylib bootstrapping to work, all modules under this
# directory must do the following:

# - If they set 'my.lib', its value can rely only on the arguments
#   'lib', 'inputs', 'flake-parts-lib' and the part of 'my.lib' set by
#   modules under this directory.

# - If they calculate imports, they may only use
#   'mylib.listImportablePathsExcept'

# It does not matter what other options they set, or what they rely on
# to do so.

let
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    mkDeferredModuleOption
    mkPerSystemOption
  ;
  inherit (lib)
    mkOption
    types
    optional
  ;
  inherit (types)
    lazyAttrsOf
    attrsOf
    unspecified
    unique
  ;

  # Imported during pre-evaluation to compensate for missing modules
  crutchmodule = { config, ... }: {
    # Gives module system errors better location information
    _file = __curPos.file + " (crutchmodule)";

    # Allows undeclared options to be set, as long as you don't try to
    # evaluate them
    freeformType = unspecified;

    # Normally set elsewhere, but needed during pre-eval
    _module.args.my = config.my;
  };
in

{
  imports =
    optional pre-eval crutchmodule ++
    [
      (mkTransposedPerSystemModule {
        name = "libFor";
        option = mkOption {
          type = attrsOf unspecified;
          default = { };
        };
        file = /. + __curPos.file;
      })
    ] ++ (
      if mylib ? listImportablePathsExcept
      then mylib.listImportablePathsExcept ./. [ "default" ]
      else [
        # Dependency closure of 'listImportablePathsExcept'
        ./listImportablePathsExcept.nix
        ./getImportableExcept.nix
        ./getImportable.nix
      ]
    );

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

    perSystem = mkPerSystemOption {
      options.my.lib = mkOption {
        type = unique { message = "Don't set 'perSystem.my.lib'. Set 'perPkgs.my.lib' instead."; } unspecified;
      };
    };
  };

  config = {
    perSystem = { my, ... }: {
      libFor = my.using.stable-uncustomized.lib;
    };

    flake = {
      lib = my.lib;
      libFunc = pkgs: (my.using pkgs).lib;
    };
  };
}
