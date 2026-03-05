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
    isString
    mapAttrs
  ;

  inherit (flake-parts-lib)
    mkDeferredModuleType
    mkPerSystemOption
  ;

  inherit (lib)
    evalModules
    fix
    mkOption
    types
  ;

  inherit (types)
    anything
    attrsOf
    either
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

    perSystem = { config, ... }: {

      nixpkgs.stable = {
        source = inputs.nixpkgs;
        arg.config.allowUnfree = true;
      };
      nixpkgs.unstable = {
        source = inputs.nixpkgs-unstable;
        inherit (config.nixpkgs.stable) arg;
      };
      nixpkgs.stable-uncustomized.source = inputs.nixpkgs;
      nixpkgs.unstable-uncustomized.source = inputs.nixpkgs-unstable;
      nixpkgs.default = "stable";

      allPkgs = fix (self: mapAttrs (n: { copyOf ? null, pkgs, ... }: if isNull copyOf then forPkgs pkgs else self.${copyOf}) config.nixpkgs);

      _module.args.pkgs = config.nixpkgs.default.pkgs;
      _module.args.forPkgs = config.allPkgs // { __functor = self: forPkgs; };

    };

    _module.args.forSystem = config.allSystems // { __functor = self: system: self.${system} or (config.perSystem); };
    _module.args.forPkgs = config.perPkgs;

  };
}
