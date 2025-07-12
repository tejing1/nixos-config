{ config, inputs, my, mylib, ... }:

# Note: Unlike in many repos, this file isn't intended as an entry
# point for nix-build. It's a flake-parts module.

{
  imports = mylib.listImportablePathsExcept ./. [
    "flake"
    "default"
  ];

  # TODO: Put this somewhere better
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  # TODO: Put this somewhere better
  _module.args.my = config.my;
  perSystem = { config, inputs', ... }: {
    _module.args = {
      my = my // config.my; # Merge the perSystem 'my' additions on top of the global 'my'
      pkgs = inputs'.nixpkgs.legacyPackages;
      pkgsUnstable = inputs'.nixpkgs-unstable.legacyPackages;
    };
  };
}
