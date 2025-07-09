{ config, inputs, mylib, ... }:

# Note: Unlike in many repos, this file isn't intended as an entry
# point for nix-build. It's a flake-parts module.

let
  inherit (builtins) attrNames;

  legacyOutputs = {
    apps = import ./apps inputs;
    homeConfigurations = import ./homeConfigurations inputs;
    homeModules = import ./homeModules inputs;
    inputs = import ./inputs.nix inputs;
    libFor = import ./libFor.nix inputs;
    libFunc = import ./libFunc inputs;
    nixosConfigurations = import ./nixosConfigurations inputs;
    nixosModules = import ./nixosModules inputs;
    overlays = import ./overlays inputs;
    packages = import ./packages.nix inputs;
    packagesFunc = import ./packagesFunc inputs;
    packagesUnstable = import ./packagesUnstable.nix inputs;
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
