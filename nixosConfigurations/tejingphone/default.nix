{ self, ... }@inputs:
hostname:
let
  nixpkgs = inputs.nixpkgs-unstable;
  system = "aarch64-linux";

  inherit (builtins) attrValues;
  inherit (self.lib) listImportablePathsExcept;
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [{
    networking.hostName = hostname;
  }]
  ++ listImportablePathsExcept ./. [ "default.nix" ]
  ++ attrValues self.nixosModules;
}
