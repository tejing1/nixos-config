{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.home-manager.url = "github:nix-community/home-manager/release-20.09";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, home-manager }: {

    nixosConfigurations.tejingdesk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
	({ pkgs, ... }: {
          # Let 'nixos-version --json' know about the Git revision
          # of this flake.
	  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
	  # register the system's version of nixpkgs and home-manager
	  nix.registry.nixpkgs.flake = nixpkgs;
	  nix.registry.home-manager.flake = home-manager;
    nix.nixPath = [ "nixpkgs=${nixpkgs}" "home-manager=${home-manager}" ];
	})
	# import home-manager
	home-manager.nixosModules.home-manager
	# import configuration.nix
	./configuration.nix
        ];
    };

  };
}
