{
  config,
  flake-parts-lib,
  forPkgs,
  inputs,
  lib,
  my,
  ...
}:

let

  inherit (builtins)
    any
    isList
    isString
    mapAttrs
    match
  ;

  inherit (flake-parts-lib)
    mkDeferredModuleType
    mkPerSystemOption
  ;

  inherit (lib)
    evalModules
    fix
    getName
    literalExpression
    mkDefault
    mkOption
    types
  ;

  inherit (types)
    anything
    attrsOf
    either
    listOf
    path
    str
    strMatching
    submodule
    unspecified
  ;

in

{
  options = {

    my.nixpkgs.release = mkOption {
      type = strMatching "[0-9][0-9]\\.(05|11)";
    };
    my.nixpkgs.config = mkOption {
      type = submodule ({
        freeformType = attrsOf types.raw;
      });
      default = {};
    };
    my.nixpkgs.overlays = mkOption {
      type = listOf path;
      default = [];
    };
    my.nixpkgs.allowUnfreePackages = mkOption {
      type = listOf str;
      description = "List of regular expressions matching unfree packages allowed to be installed";
      default = [];
      example = literalExpression ''[ "steam" "nvidia-.*" ]'';
    };
    my.nixpkgs.args = mkOption {
      type = types.raw;
      readOnly = true;
      internal = true;
    };

    perSystem = mkPerSystemOption ({ system, ... }: {
      options = {

        nixpkgs = mkOption {
          type = attrsOf (either str (submodule ({ config, ... }: {
            options = {
              src = mkOption {
                type = path;
              };
              args = mkOption {
                type = types.addCheck (attrsOf types.raw) (args: ! args ? system && ! args ? localSystem);
              };
              pkgs = mkOption {
                type = types.pkgs;
              };
            };

            config = {
              # Forces nixpkgs purity even if evaluating impurely
              args.config = mkDefault {};
              args.overlays = mkDefault [];

              pkgs = import config.src (config.args // { inherit system; });
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

  };

  config = {

    my.nixpkgs.release = "25.11";

    my.flake.inputs = {
      nixpkgs.url          = "github:NixOS/nixpkgs/nixos-${my.nixpkgs.release}";
      nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    my.nixpkgs.config.allowUnfreePredicate = pkg: any (reg: isList (match reg (getName pkg))) my.nixpkgs.allowUnfreePackages;

    my.nixpkgs.args = { inherit (my.nixpkgs) config overlays; };

    perSystem = { config, ... }: {

      nixpkgs.stable = {
        src = inputs.nixpkgs;
        inherit (my.nixpkgs) args;
      };
      nixpkgs.unstable = {
        src = inputs.nixpkgs-unstable;
        inherit (my.nixpkgs) args;
      };
      nixpkgs.stable-uncustomized.src = inputs.nixpkgs;
      nixpkgs.unstable-uncustomized.src = inputs.nixpkgs-unstable;
      nixpkgs.default = "stable";

      allPkgs = fix (self: mapAttrs (n: { copyOf ? null, pkgs, ... }: if isNull copyOf then forPkgs pkgs else self.${copyOf}) config.nixpkgs);

      _module.args.pkgs = config.nixpkgs.default.pkgs;
      _module.args.forPkgs = config.allPkgs // { __functor = self: forPkgs; };

    };

    _module.args.forSystem = config.allSystems // { __functor = self: system: self.${system} or (config.perSystem); };
    _module.args.forPkgs = config.perPkgs;

  };
}
