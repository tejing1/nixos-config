{
  flake-parts-lib,
  forPkgs,
  lib,
  my,
  mylib,
  self,
  ...
}:

let
  inherit (builtins)
    elem
  ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    mkDeferredModuleOption
    mkPerSystemOption
  ;
  inherit (lib)
    mkOption
    types
    filterAttrs
    mkMerge
  ;
  inherit (types)
    attrsOf
    lazyAttrsOf
    package
    unspecified
    unique
  ;
in

{
  imports = [
    # Add a non-standard system-spaced flake output for packages built against nixpkgs unstable
    (mkTransposedPerSystemModule {
      name = "packagesUnstable";
      option = mkOption {
        type = lazyAttrsOf package;
        default = {};
      };
      file = /. + __curPos.file;
    })
  ] ++ mylib.listImportablePathsExcept ./. [ "default" ];

  options = {
    perPkgs = mkDeferredModuleOption {
      options.my.pkgs = mkOption {
        type = attrsOf package;
      };
    };
    perSystem = mkPerSystemOption {
      options = {
        my.pkgs = mkOption {
          type = unique { message = "Don't set 'perSystem.my.pkgs'. Set 'perPkgs.my.pkgs' instead."; } unspecified;
        };
        my.pkgsUnstable = mkOption {
          type = unique { message = "Don't set 'perSystem.my.pkgsUnstable'. Set 'perPkgs.my.pkgs' instead."; } unspecified;
        };
      };
    };
  };

  config = mkMerge [
    # Provide packages for internal use
    {
      perSystem = { forOurPkgs, pkgsUnstable, ... }: {
        my.pkgs = forOurPkgs.my.pkgs;
        my.pkgsUnstable = (forPkgs pkgsUnstable).my.pkgs;
      };
    }

    # Provide packages for external use
    {
      # Filter by meta.platforms so we don't expose non-working flake outputs
      flake.packagesFunc = pkgs: filterAttrs (n: p: ! p ? meta || ! p.meta ? platforms || elem pkgs.system p.meta.platforms) (forPkgs pkgs).my.pkgs;

      # Use self.packagesFunc here rather than forOurPkgs.my.pkgs,
      # because we want the filtering. Also get our pkgs value
      # directly from inputs, so we don't export local nixpkgs config
      perSystem = { inputs', ... }: {
        packages = self.packagesFunc inputs'.nixpkgs.legacyPackages;
        packagesUnstable = self.packagesFunc inputs'.nixpkgs-unstable.legacyPackages;
      };
    }
  ];
}
