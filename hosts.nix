{
  config,
  flake-parts-lib,
  lib,
  ...
}:

let

  inherit (flake-parts-lib)
    mkDeferredModuleType
  ;

  inherit (lib)
    mkOption
    types
  ;

  inherit (types)
    attrsOf
    enum
    submodule
  ;

in

{
  options = {
    hosts = mkOption {
      type = attrsOf (submodule {
        imports = config.perHost;
        options.type = mkOption {
          type = enum [ ];
        };
      });
      default = {};
    };
    perHost = mkOption {
      type = mkDeferredModuleType {};
      default = {};
    };
  };
}
