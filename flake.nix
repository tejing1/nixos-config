{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.home-manager.url = "github:nix-community/home-manager/release-20.09";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, home-manager }: {

    nixosConfigurations.tejingdesk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Let 'nixos-version --json' know about the Git revision
        # of this flake.
	({ pkgs, ... }: {system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;})
	# import configuration.nix
	(import ./configuration.nix {inherit nixpkgs home-manager;})
        ];
    };

  };
}
