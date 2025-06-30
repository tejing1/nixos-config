inputs@{ nixpkgs, ... }:

let
  inherit (nixpkgs.lib)
    genAttrs
  ;

  # functions needed to construct 'lib' itself
  bootstrapFunctions = [
    "importAllExceptWithArg"
    "getImportableExcept"
    "getImportable"
  ];

  # arguments to files in this directory, except for 'my.lib'
  commonArgs = inputs // { inherit inputs; inherit (nixpkgs) lib; };

  # bootstrap lib containing only 'bootstrapFunctions'
  initialLib = genAttrs bootstrapFunctions (n: import (./. + "/${n}.nix") (commonArgs // { my.lib = initialLib; }));

  # externally visible 'lib'
  finalLib = initialLib.importAllExceptWithArg ./. [ "default" ] (commonArgs // { my.lib = finalLib; });

in finalLib
