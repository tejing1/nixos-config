{ config, flake-parts-lib, forPkgs, lib, my, mylib, ... }:

let
  inherit (flake-parts-lib) mkDeferredModuleOption mkPerSystemOption;
  inherit (lib) mkOption types;
  inherit (types) functionTo lazyAttrsOf unspecified unique;
  inherit (my.lib) importAllExceptWithArg;
in

{
  imports = mylib.listImportablePathsExcept ./. [ "default" ];

  options = {
    perPkgs = mkDeferredModuleOption {
      options.my.lib = mkOption {
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
    perPkgs.my.lib = my.lib;

    perSystem = { forOurPkgs, ... }: {
      my.lib = forOurPkgs.my.lib;
    };

    flake.libFunc = pkgs: (forPkgs pkgs).my.lib;
  };
}
