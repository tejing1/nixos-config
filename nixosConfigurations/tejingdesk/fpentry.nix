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

    hm.src = home-manager;
    hm.module = true;
    users.tejing.type = "hm-module";

    nixos.cfg.imports = listImportablePathsExcept ./. [ "fpentry" ];

    # FIXME commented at source to avoid infrec with internal instantiation
    nixos.cfg.nixpkgs.config.allowUnfree = true;
    nixos.cfg.nixpkgs.overlays = [
      # Prevents gh from leaving garbage characters in the input
      # buffer when urxvt is set to a transparent background
      inputs.self.overlays.gh-urxvt-fix-termenv
    ];
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
      }
      {
        # FIXME commented at source to avoid infrec with internal instantiation
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          # Prevents gh from leaving garbage characters in the input
          # buffer when urxvt is set to a transparent background
          inputs.self.overlays.gh-urxvt-fix-termenv
        ];

        # FIXME moved here for separate implementation
        home-manager.users.tejing.imports = [ inputs.self.homeConfigurations.tejing.configurationModule ];
      }
    ]
    ++ listImportablePathsExcept ./. [ "fpentry" ]
    ++ attrValues inputs.self.nixosModules;
  };

}
