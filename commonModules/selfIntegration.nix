{ config, inputs, lib, pkgs, ... }:
let
  inherit (builtins) listToAttrs mapAttrs parseFlakeRef;
  inherit (lib) mkOption types hasPrefix hasInfix zipListsWith nameValuePair splitString removePrefix;

  flakeNixInputs = (import (inputs.self + "/flake.nix")).inputs;

  canonicalizeInputSpec = spec: if spec ? url then removeAttrs spec [ "url" ] // parseFlakeRef spec.url else spec;
in
{
  config._module.args.inputSpecs = mapAttrs (_: canonicalizeInputSpec) flakeNixInputs;

  config._module.args.my = config.my;

  options.my.lib = mkOption {
    type = types.unspecified;
    description = "Library functions from self";
    visible = false;
    readOnly = true;
  };
  config.my.lib = inputs.self.libFunc pkgs;

  options.my.overlays = mkOption {
    type = types.unspecified;
    description = "Overlays from self.overlays";
    visible = false;
    readOnly = true;
  };
  config.my.overlays = inputs.self.overlays;

  options.my.pkgs = mkOption {
    type = types.unspecified;
    description = "Packages from self";
    visible = false;
    readOnly = true;
  };
  config.my.pkgs = inputs.self.packagesFunc pkgs;

  options.my.pkgsUnstable = mkOption {
    type = types.unspecified;
    description = "Packages from self, with dependencies from unstable";
    visible = false;
    readOnly = true;
  };
  config.my.pkgsUnstable = inputs.self.packagesFunc inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
}
