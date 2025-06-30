inputs@{ self, ... }:
pkgs:
let
  inherit (self.lib) importAllExceptWithArg;

  result = self.lib //
    # import everything in this directory
    importAllExceptWithArg ./. [ "default" ] (
      inputs //
      {
        inherit pkgs;
        inherit (pkgs) lib;

        # pass the final (merged) structure as my.lib
        my.lib = result;
      }
    );
in result
