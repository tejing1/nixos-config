{ inputs, lib, my, ... }:

let

  inherit (builtins)
    mapAttrs
    parseFlakeRef
  ;
  inherit (lib)
    mkEnableOption
  ;

  flakeNixInputs = (import (inputs.self + "/flake.nix")).inputs;

  canonicalizeInputSpec = spec: if spec ? url then removeAttrs spec [ "url" ] // parseFlakeRef spec.url else spec;
in

{
  flake.nixosModules = my.lib.getImportableExcept ./. [ "fpentry" ];

  perHost.nixos.cfg = { lib, my, ... }: let
    inherit (lib) mkOption types;
  in {
    imports = [
      customization/nix.nix
      customization/registry.nix
      customization/shells.nix
      users/tejing/default.nix
    ];

    config._module.args.inputSpecs = mapAttrs (_: canonicalizeInputSpec) flakeNixInputs;

    options.my.isBuildVm = mkOption {
      type = types.bool;
      description = "Whether the system being built is part of a nixos-rebuild build-vm or build-vm-with-bootloader";
      default = false;
    };
    options.my.isBuildVmWithBootLoader = mkOption {
      type = types.bool;
      description = "Whether the system being built is part of a nixos-rebuild build-vm-with-bootloader";
      default = false;
    };

    config.virtualisation.vmVariant.my.isBuildVm = true;
    config.virtualisation.vmVariantWithBootLoader.my.isBuildVm = true;
    config.virtualisation.vmVariantWithBootLoader.my.isBuildVmWithBootLoader = true;
    config.home-manager.sharedModules = [{
      my.isBuildVm = my.isBuildVm;
      my.isBuildVmWithBootLoader = my.isBuildVmWithBootLoader;
    }];

    # FIXME here so the option is defined for now
    options.my.customize.users = mkEnableOption "customization of options applying to all users";
    # Strictly definitional users, passwords, and groups
    config.users.mutableUsers = false;
  };
}
