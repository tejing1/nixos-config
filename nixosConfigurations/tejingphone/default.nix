inputs: hostname:
let
  nixpkgsInput = "nixpkgs-unstable";
  home-managerInput = "home-manager-unstable";

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
  ++ listImportablePathsExcept ./. [ "default.nix" ]
  ++ attrValues inputs.self.nixosModules;
}
