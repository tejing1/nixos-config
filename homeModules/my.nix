{ lib, ... }:
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
}
