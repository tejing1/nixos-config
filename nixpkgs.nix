{
  config,
  flake-parts-lib,
  getSystem,
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
    mergeOneOption
    mkDefault
    mkIf
    mkOption
    mkOptionType
    types
  ;

  inherit (types)
    attrsOf
    either
    listOf
    str
    strMatching
    submodule
    submoduleWith
    unspecified
  ;

  getPkgs = config.perPkgs;

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
      type = listOf (types.functionTo (types.functionTo unspecified));
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
                type = my.lib.types.flakeInput;
              };
              args = mkOption {
                type = types.addCheck (attrsOf types.raw) (args: ! args ? system && ! args ? localSystem);
              };
              pkgs = mkOption {
                type = types.pkgs;
                default = import config.src (config.args // { inherit system; });
              };
            };

            config = {
              # Forces nixpkgs purity even if evaluating impurely
              args.config = mkDefault {};
              args.overlays = mkDefault [];
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

    hosts = mkOption {
      type = attrsOf (submodule ({ config, name, thisSystem, pkgsFrom, pkgs, ... }: {
        options = {
          nixpkgs.system = mkOption {
            type = types.str;
            description = "Nix system-string. Used to set nixpkgs.hostPlatform and to determine which system to look under for the relevant perPkgs instance.";
          };
          nixpkgs.name = mkOption {
            type = types.str;
            default = name;
            defaultText = lib.literalExpression "name";
            description = "Name of the perPkgs instance to use with this host.";
          };
          nixpkgs.src = mkOption {
            type = my.lib.types.flakeInput;
            description = "Flake input to get nixpkgs contents, and in particular, lib.nixosSystem and possibly nixosModules.readOnlyPkgs, from.";
          };
          nixpkgs.instantiation = mkOption {
            type = types.enum [ "external" "internal" ];
            default = "external";
            description = "Whether to import an external instantiation of nixpkgs or export the internal one.";
          };
          users = mkOption {
            type = attrsOf (submoduleWith {
              modules = [
                {
                  _module.args.pkgsFrom = pkgsFrom;
                  _module.args.pkgs = pkgs;
                }
              ];
            });
          };
        };
        config = {
          nixpkgs.src = mkIf (config.nixpkgs.instantiation == "external") thisSystem.nixpkgs.${config.nixpkgs.name}.src;
          _module.args.thisSystem = getSystem config.nixpkgs.system;
          _module.args.pkgsFrom = mapAttrs (n: v: v.pkgs) thisSystem.nixpkgs;
          _module.args.pkgs = pkgsFrom.${config.nixpkgs.name};
        };
      }));
    };
  };

  config = {
    my.lib.types.flakeInput = mkOptionType {
      name = "flake";
      description = "flake input";
      descriptionClass = "noun";
      check = types.isType "flake";
      merge = mergeOneOption;
    };

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

      allPkgs = fix (self: mapAttrs (n: { copyOf ? null, pkgs, ... }: if isNull copyOf then getPkgs pkgs else self.${copyOf}) config.nixpkgs);

      _module.args.pkgs = config.nixpkgs.default.pkgs;
      _module.args.forPkgs = config.allPkgs // {
        __functor = self: pkgs:
          if isString pkgs then
            self.${pkgs}
          else
            config.perPkgs pkgs;
      };

    };

    _module.args.forSystem = config.allSystems // {
      __functor = self: system: self.${system} or (config.perSystem system);
    };
    _module.args.forPkgs = mapAttrs (n: v: v.allModuleArgs.forPkgs) config.allSystems // {
      __functor = self: arg:
        if isString arg then
          self.${arg} or ((config.perSystem arg).allModuleArgs.forPkgs)
        else
          config.perPkgs arg;
    };

  };
}
