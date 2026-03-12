{ inputs, my, ... }:

{
  flake.nixosConfigurations = my.lib.importAllNamedExceptWithArg ./. [ "fpentry" ] inputs;
}
