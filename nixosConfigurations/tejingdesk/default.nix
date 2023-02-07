inputs: hostname:
let
  nixpkgs = inputs.nixpkgs;
  home-manager = inputs.home-manager;
  system = "x86_64-linux";

  inherit (builtins) attrValues;
  inherit (inputs.self.lib) listImportablePathsExcept;
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs nixpkgs home-manager;
  };
  modules = [{
    networking.hostName = hostname;
  }]
  ++ listImportablePathsExcept ./. [ "default.nix" ]
  ++ attrValues inputs.self.nixosModules;
}
