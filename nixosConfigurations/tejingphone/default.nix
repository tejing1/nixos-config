inputs: hostname:
let
  nixpkgs = inputs.nixpkgs-unstable;
  home-manager = inputs.home-manager-unstable;

  inherit (builtins) attrValues;
  inherit (inputs.self.lib) listImportablePathsExcept;
in
nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs nixpkgs home-manager;
  };
  modules = [{
    networking.hostName = hostname;
  }]
  ++ listImportablePathsExcept ./. [ "default.nix" ]
  ++ attrValues inputs.self.nixosModules;
}
