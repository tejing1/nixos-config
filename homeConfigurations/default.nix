{ inputs, my, ... }:

{
  flake.homeConfigurations = my.lib.importAllNamedExceptWithArg ./. [ "default" ] inputs;
}
