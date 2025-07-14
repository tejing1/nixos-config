{ config, flake-parts-lib, forPkgs, lib, ... }:

let
  inherit (flake-parts-lib) mkDeferredModuleType;
  inherit (lib) mkOption types evalModules;
  inherit (types) deferredModuleWith;
in

{
  options = {
    perPkgs = mkOption {
      type = mkDeferredModuleType ({ config, ... }: {
        # TODO: move this somewhere better
        _module.args.my = config.my;
      });
      apply = modules: pkgs: (evalModules {
        inherit modules;
        prefix = [ "perPkgs" "<function body>" ];
        specialArgs = {
          inherit pkgs;
        };
        class = "perPkgs";
      }).config;
    };
  };

  config = {
    perSystem = { config, pkgs, ... }: {
      # This isn't just a convenience, it memoizes access on a per
      # system basis
      _module.args.forOurPkgs = forPkgs pkgs;
    };
    _module.args.forPkgs = config.perPkgs;
    #_module.args.withPkgs = pkgs: f: ;
  };
}
