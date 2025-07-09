{ flake-parts-lib, lib, self, ... }:

let
  inherit (flake-parts-lib) mkTransposedPerSystemModule;
  inherit (lib) mkOption types;
in

{
  imports = [
    (mkTransposedPerSystemModule {
      name = "libFor";
      option = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = { };
      };
      file = ./libFor.nix;
    })
  ];
  perSystem = { pkgs, ... }: {
    libFor = self.libFunc pkgs;
  };
}
