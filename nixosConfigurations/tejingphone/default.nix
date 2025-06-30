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
  system = "aarch64-linux"; # mobile-nixos still needs this set. It can't work from nixpkgs.hostPlatorm
  specialArgs = {
    inherit inputs nixpkgs home-manager nixpkgsInput home-managerInput;
  };
  modules = [{
    networking.hostName = hostname;
  }]
  ++ listImportablePathsExcept ./. [ "default" ]
  ++ attrValues inputs.self.nixosModules;
}
