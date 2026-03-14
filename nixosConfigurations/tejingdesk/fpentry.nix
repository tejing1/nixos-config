{ inputs, my, ... }:

let
  nixpkgsInput = "nixpkgs";
  home-managerInput = "home-manager";

  nixpkgs = inputs.${nixpkgsInput};
  home-manager = inputs.${home-managerInput};

  inherit (builtins) attrValues;
  inherit (my.lib) listImportablePathsExcept;
in

{
  flake.nixosConfigurations.tejingdesk = nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs nixpkgs home-manager nixpkgsInput home-managerInput;
    };
    modules = [{
      networking.hostName = "tejingdesk";
    }]
    ++ listImportablePathsExcept ./. [ "fpentry" ]
    ++ attrValues inputs.self.nixosModules;
  };
}
