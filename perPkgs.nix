{
  config,
  flake-parts-lib,
  forPkgs,
  inputs,
  lib,
  ...
}:

let
  inherit (builtins)
    mapAttrs
    isString
    hasAttr
  ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    mkPerSystemOption
    mkDeferredModuleType
  ;
  inherit (lib)
    mkOption
    types
    evalModules
    fix
  ;
  inherit (types)
    attrsOf
    submodule
    anything
    path
    deferredModuleWith
    unspecified
    either
    str
    nullOr
  ;
in

{
  options = {
    perPkgs = mkOption {
      type = mkDeferredModuleType {};
      apply = modules: pkgs: (evalModules {
        inherit modules;
        prefix = [ "perPkgs" ];
        specialArgs = {
          inherit pkgs;
        };
        class = "perPkgs";
      }).config;
    };

    perSystem = mkPerSystemOption ({ system, ... }: {
      options = {
        nixpkgs = mkOption {
          type = attrsOf (either str (submodule ({ config, ... }: {
            options = {
              source = mkOption {
                type = path;
              };
              arg = mkOption {
                type = anything;
              };
              pkgs = mkOption {
                type = types.pkgs;
              };
            };

            config = {
              arg.system = system;

              pkgs = import config.source config.arg;
            };
          })));
          apply = attrs: fix (self: mapAttrs (n: v:
            if ! isString v then
              v
            else if ! self.${v} ? copyOf then
              self.${v} // { copyOf = v; }
            else
              self.${v}
          ) attrs);
        };
        allPkgs = mkOption {
          type = attrsOf unspecified;
          internal = true;
          readOnly = true;
        };
      };
    });
  };

  config = {
    perSystem = { config, ... }: {
      allPkgs = fix (self: mapAttrs (n: { copyOf ? null, pkgs, ... }: if isNull copyOf then forPkgs pkgs else self.${copyOf}) config.nixpkgs);

      _module.args.pkgs = config.nixpkgs.default.pkgs;
      _module.args.forPkgs = config.allPkgs // { __functor = self: forPkgs; };
    };

    _module.args.forSystem = config.allSystems // { __functor = self: system: if hasAttr system self then self.${system} else config.perSystem; };
    _module.args.forPkgs = config.perPkgs;
  };
}
