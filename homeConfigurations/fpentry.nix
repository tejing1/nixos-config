{ inputs, my, ... }:

{
  flake.homeConfigurations = my.lib.importAllNamedExceptWithArg ./. [ "fpentry" ] inputs;
}
