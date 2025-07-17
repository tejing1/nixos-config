{ inputs, mylib, ... }:

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

  flake = {
    # Useful for debugging
    inherit inputs;
  };
}
