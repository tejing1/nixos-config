{
  flake-parts-lib,
  lib,
  my,
  mylib,
  ...
}:

let
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    mkDeferredModuleOption
    mkPerSystemOption
  ;
  inherit (lib)
    mkOption
    types
    makeScope
    const
    filterAttrs
    isDerivation
  ;
  inherit (types)
    attrsOf
    package
    lazyAttrsOf
    unique
    unspecified
  ;
in

{
  imports = [
    # Add a non-standard system-spaced flake output for packages built against nixpkgs unstable
    (mkTransposedPerSystemModule {
      name = "packagesUnstable";
      option = mkOption {
        type = attrsOf package;
        default = {};
      };
      file = /. + __curPos.file;
    })
  ] ++ mylib.listImportablePathsExcept ./. [ "default" ];

  options = {
    perPkgs = mkDeferredModuleOption ({ pkgs, ... }: {
      options.my.pkgs = mkOption {
        # Give up attr deletion through priorities/conditions to allow
        # more recursion. Otherwise the module system tries to eval each
        # package enough to figure out it isn't a mkIf or mkDefault
        # or whatnot, before it finalizes the set of attribute names
        # under my.pkgs. If that much evaluation requires something from
        # my.pkgs, we get infrec.
        type = lazyAttrsOf package;
        apply = ps: makeScope pkgs.newScope (const ps);
      };
    });

    perSystem = mkPerSystemOption {
      options = {
        my.pkgs = mkOption {
          type = unique { message = "Don't set 'perSystem.my.pkgs'. Set 'perPkgs.my.pkgs' instead."; } unspecified;
        };
      };
    };
  };

  config = {
    # Filter packages by supported system unless the consumer has configured nixpkgs to allow unsupported systems
    flake.packagesFunc = pkgs: filterAttrs (n: p: isDerivation p && (pkgs.config.allowUnsupportedSystem || ! p.meta.unsupported)) (my.using pkgs).pkgs;

    perSystem = { my, ... }: {
      packages = filterAttrs (n: p: isDerivation p && ! p.meta.unsupported) my.using.stable-uncustomized.pkgs;
      packagesUnstable = filterAttrs (n: p: isDerivation p && ! p.meta.unsupported) my.using.unstable-uncustomized.pkgs;
    };
  };
}
