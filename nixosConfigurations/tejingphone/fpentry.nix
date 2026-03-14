{ inputs, my, ...}:

let
  nixpkgsInput = "nixpkgs-unstable";
  home-managerInput = "home-manager-unstable";

  nixpkgs = inputs.${nixpkgsInput};
  home-manager = inputs.${home-managerInput};

  inherit (builtins) attrValues;
  inherit (my.lib) listImportablePathsExcept;
in

{
  flake.nixosConfigurations.tejingphone = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux"; # mobile-nixos still needs this set. It can't work from nixpkgs.hostPlatorm
    specialArgs = {
      inherit inputs nixpkgs home-manager nixpkgsInput home-managerInput;
    };
    modules = [{
      networking.hostName = "tejingphone";
    }]
    ++ listImportablePathsExcept ./. [ "fpentry" ]
    ++ attrValues inputs.self.nixosModules;
  };
}
