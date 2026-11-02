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
    mkEnableOption
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
        options.enable = mkEnableOption "this host";
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
