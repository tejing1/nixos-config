{ inputs, my, ... }:

{
  flake.nixosConfigurations = my.lib.importAllNamedExceptWithArg ./. [ "default" ] inputs;
}
