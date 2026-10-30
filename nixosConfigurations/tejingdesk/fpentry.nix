{
  inputs,
  my,
  ...
}:

let
  nixpkgsInput = "nixpkgs";
  home-managerInput = "home-manager";

  nixpkgs = inputs.${nixpkgsInput};
  home-manager = inputs.${home-managerInput};

  inherit (builtins) attrValues;
  inherit (my.lib) listImportablePathsExcept;
in

{
  hosts.tejingdesk = {
    type = "nixos";

    #nixpkgs.system = "x86_64-linux";
    #nixpkgs.name = "stable";

    nixpkgs.src = nixpkgs;
    nixpkgs.instantiation = "internal";
    nixos.cfg.nixpkgs.hostPlatform = "x86_64-linux";

    hm.src = home-manager;
    hm.module = true;
    users.tejing.type = "hm-module";

    nixos.cfg.imports = listImportablePathsExcept ./. [ "fpentry" ];
  };

  # FIXME move all this to the proper locations after they are converted to flake-parts modules
  my.nixpkgs.allowUnfreePackages = [
    "nvidia-x11"
    "nvidia-settings"
    "steam"
    "steam-unwrapped"
    "starsector"
  ];
  my.nixpkgs.overlays = [
    my.overlays.gh-urxvt-fix-termenv
  ];


  # Keeping the old invocation for comparison purposes
  flake.nixosConfigurations.tejingdesk2 = nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs nixpkgs home-manager nixpkgsInput home-managerInput;
    };
    modules = [
      {
        networking.hostName = "tejingdesk";
        nixpkgs.hostPlatform = "x86_64-linux";
      }
    ]
    ++ listImportablePathsExcept ./. [ "fpentry" ]
    ++ attrValues inputs.self.nixosModules;
  };

}
