{ config, inputs, mylib, ... }:

# Note: Unlike in many repos, this file isn't intended as an entry
# point for nix-build. It's a flake-parts module.

let
  inherit (builtins) attrNames;

  legacyOutputs = {
    homeModules = import ./homeModules inputs;
    nixosModules = import ./nixosModules inputs;
  };
in

{
  imports = mylib.listImportablePathsExcept ./. ([
    "flake"
    "default"
  ] ++ attrNames legacyOutputs);

  flake = legacyOutputs;

  # TODO: Put this somewhere better
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  # TODO: Put this somewhere better
  _module.args.my = config.my;
}
