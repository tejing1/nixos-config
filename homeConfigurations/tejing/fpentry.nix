{ inputs, my, ... }:

let

  nixpkgs = inputs.nixpkgs;
  home-manager = inputs.home-manager;
  system = "x86_64-linux";

  inherit (nixpkgs.lib) mkDefault;
  inherit (home-manager.lib) homeManagerConfiguration;
  inherit (my.lib) listImportablePathsExcept;

  modules = [
    {
      home.username = mkDefault "tejing";
      home.homeDirectory = mkDefault "/home/tejing";
    }
    inputs.self.homeModules.tejing
  ] ++ (listImportablePathsExcept ./. [ "fpentry" ]);

in

{
  users.tejing.hm.cfg = {
    imports = modules;
  };

  flake.homeConfigurations.tejing =
    { configurationModule.imports = modules; } //
    homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {
        inherit inputs nixpkgs home-manager;
      };
      modules = modules ++ [ inputs.self.homeModules.my ];
    };
}
