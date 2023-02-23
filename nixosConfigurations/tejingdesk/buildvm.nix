{ lib, my, ... }:
let
  inherit (lib) mkMerge mkIf mkVMOverride;

  # These options don't exist to set when not doing a build-vm, so we
  # can't use a mkIf for this
  vmVariant = { ... }: {
    virtualisation.memorySize = 4096;
    virtualisation.msize = 1024*1024;
    virtualisation.cores = 6;
    virtualisation.writableStoreUseTmpfs = false;
  };
  vmVariantWithBootLoader = { ... }: {
    #virtualisation.useEFIBoot = true;
  };
in
mkMerge [
  (mkIf my.isBuildVm (mkVMOverride {
    services.xserver.displayManager.autoLogin.enable = true;
    services.xserver.displayManager.autoLogin.user = "tejing";
    security.sudo.wheelNeedsPassword = false;
  }))
  (mkIf my.isBuildVm {
    systemd.tmpfiles.rules = [ "d ${my.command-not-found.stateDir} 755 root root -" ];
  })
  {
    virtualisation.vmVariant.imports = [ vmVariant ];
    virtualisation.vmVariantWithBootLoader.imports = [ vmVariant vmVariantWithBootLoader ];
  }
  (mkIf my.isBuildVmWithBootLoader (mkVMOverride {
    boot.loader.efi.efiSysMountPoint = "/boot";
    # TODO: Make the system closure properly registered in the nix db
  }))
]
