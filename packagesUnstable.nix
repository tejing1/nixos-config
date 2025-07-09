{ flake-parts-lib, lib, self, ... }:

let
  inherit (flake-parts-lib) mkTransposedPerSystemModule;
  inherit (lib) mkOption types;
in

{
  imports = [
    (mkTransposedPerSystemModule {
      name = "packagesUnstable";
      option = mkOption {
        type = types.lazyAttrsOf types.package;
        default = { };
      };
      file = ./packagesUnstable.nix;
    })
  ];
  perSystem = { inputs', ... }: {
    packagesUnstable = self.packagesFunc inputs'.nixpkgs-unstable.legacyPackages;
  };
}
