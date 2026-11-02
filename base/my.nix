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
    addErrorContext
    mkOption
    toList
    types
  ;
  inherit (types)
    attrsOf
    unspecified
  ;

  # Type modifier which only allows definitions coming from the specified file
  # For a normal option we'd just mark it readOnly, but that doesn't work for freeformType
  onlyfromfile = file: type: type // {
    merge = loc: defs:
      if all (def: def.file == file) defs then
        type.merge loc defs
      else
        addErrorContext "while evaluating the error message for ${lib.options.showOption loc}, which was set from a different file than the allowed one"
        (throw ''
          The option ${lib.options.showOption loc} was set from a different file than the allowed one (${file}).
          Offending definition values:${lib.options.showDefs (filter (def: def.file != file) defs)}
        '');
  };

  # Creates a submodule option with a freeformType allowing additional data to be supplied, but only in this file.
  # Make sure to use the argument 'lib' here for any module system functions or types.
  mkMyOption = lib: module: lib.mkOption {
    type = lib.types.submodule ([{
      freeformType = onlyfromfile __curPos.file lib.types.unspecified;
    }] ++ toList module);
  };

  # Make sure to use the module's 'lib' here for any module system functions or types.
  homeModule = userConfig:
    { config, lib, ... }: {
      options.my = mkMyOption lib {};
      config = {
        _module.args.my = config.my;
        inherit (userConfig) my;
      };
    };

  # Make sure to use the module's 'lib' here for any module system functions or types.
  nixosModule = hostConfig:
    { config, lib, ... }: {
      options.my = mkMyOption lib {};
      config = {
        _module.args.my = config.my;
        inherit (hostConfig) my;
      };
    };

  userModule = hostConfig:
    { config, ... }: {
      options.hm.cfg = mkDeferredModuleOption (homeModule config);
      options.my = mkMyOption lib {};
      config = {
        _module.args.my = config.my;
        inherit (hostConfig) my;
      };
    };
in

{
  options = {
    my.using = mkOption {
      type = attrsOf unspecified;
    };
    perPkgs = mkDeferredModuleOption ({ config, ... }: {
      options.my = mkMyOption lib {
        options.using = mkOption {
          type = attrsOf unspecified;
        };
      };
      config = {
        _module.args.my = config.my;
        inherit my;
      };
    });
    perSystem = mkPerSystemOption ({ config, ... }: {
      options.my = mkMyOption lib {};
      config = {
        _module.args.my = config.my;
        inherit (config.allPkgs.default) my;
      };
    });
    hosts = mkOption {
      type = attrsOf (types.submodule ({ config, ... }: {
        options.nixos.cfg = mkDeferredModuleOption (nixosModule config);
        options.users = mkOption {
          type = attrsOf (types.submoduleWith { modules = [ (userModule config) ]; });
        };
        options.my = mkMyOption lib {};
        config = {
          _module.args.my = config.my;
          inherit (forPkgs config.nixpkgs.system config.nixpkgs.name) my;
        };
      }));
    };
  };

  config = {
    _module.args.my = config.my;
    my.using.__functor = self: pkgs: (forPkgs pkgs).my;

    perPkgs = { pkgs, ... }: {
      my.using = mapAttrs (n: v: v.my) (forSystem pkgs.stdenv.hostPlatform.system).allPkgs;
    };
  };
}
