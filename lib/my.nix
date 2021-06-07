{ config, lib, ... }:

{
  options.my = with lib; mkOption {
    type = types.lazyAttrsOf types.anything;
    default = {};
    description = "A value to be merged and passed as argument 'my'.";
  };
  config._module.args.my = config.my;
}
