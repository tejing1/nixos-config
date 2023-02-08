inputs: username:
let
  nixpkgs = inputs.nixpkgs;
  home-manager = inputs.home-manager;
  system = "x86_64-linux";

  inherit (builtins) attrValues;
  inherit (nixpkgs.lib) mkDefault;
  inherit (home-manager.lib) homeManagerConfiguration;
  inherit (inputs.self.lib) listImportablePathsExcept;

  modules = [
    {
      home.username = mkDefault username;
      home.homeDirectory = mkDefault "/home/${username}";
      nixpkgs.config.allowUnfreePredicate = _: true;
    }
    inputs.self.homeModules.${username}
  ] ++ (listImportablePathsExcept ./. [ "default.nix" ]);
in
{ configurationModule.imports = modules; } //
homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.${system};
  extraSpecialArgs = {
    inherit inputs nixpkgs home-manager;
  };
  modules = modules ++ [ inputs.self.homeModules.my ];
}
