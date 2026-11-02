{
  config,
  flake-parts-lib,
  lib,
  ...
}:

let

  inherit (builtins)
    mapAttrs
  ;

  inherit (flake-parts-lib)
    mkDeferredModuleType
  ;

  inherit (lib)
    mkEnableOption
    mkOption
    types
  ;

  inherit (types)
    attrsOf
    enum
    submodule
    submoduleWith
  ;

in

{
  options = {
    hosts = mkOption {
      type = attrsOf (submodule {
        options.users = mkOption {
          type = attrsOf (submoduleWith {
            modules = [
              ({ name, ... }: {
                imports = config.perUser;
                options.enable = mkEnableOption "this user";
                options.type = mkOption {
                  type = enum [];
                };
              })
            ];
          });
          default = {};
        };
        config.users = mapAttrs (name: modules: { imports = modules; }) config.users;
      });
    };
    users = mkOption {
      type = attrsOf (mkDeferredModuleType {
      });
      default = {};
    };
    perUser = mkOption {
      type = mkDeferredModuleType {};
      default = {};
    };
  };
}
