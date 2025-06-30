inputs: hostname:
let
  nixpkgsInput = "nixpkgs";
  home-managerInput = "home-manager";

  nixpkgs = inputs.${nixpkgsInput};
  home-manager = inputs.${home-managerInput};

  inherit (builtins) attrValues;
  inherit (inputs.self.lib) listImportablePathsExcept;
in
nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs nixpkgs home-manager nixpkgsInput home-managerInput;
  };
  modules = [{
    networking.hostName = hostname;
  }]
  ++ listImportablePathsExcept ./. [ "default" ]
  ++ attrValues inputs.self.nixosModules;
}
