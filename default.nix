{ config, inputs, mylib, ... }:

# Note: Unlike in many repos, this file isn't intended as an entry
# point for nix-build. It's a flake-parts module.

{
  imports = [ ./lib ];

  flake = mylib.importAllExceptWithArg ./. [ "flake" "lib" "default" ] inputs;

  # TODO: Put this somewhere better
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  # TODO: Put this somewhere better
  _module.args.my = config.my;
}
