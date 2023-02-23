{ lib, my, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [ ../commonModules/selfIntegration.nix ];

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
}
