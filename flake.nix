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
    nix.nixPath = [ "/etc/nix/path" ];

	  # the version of nixpkgs used to build the system
	  nix.registry.nixpkgs.flake = nixpkgs;
    environment.etc."nix/path/nixpkgs".source = nixpkgs;

	  # the version of home-manager used to build the system
	  nix.registry.home-manager.flake = home-manager;
    environment.etc."nix/path/home-manager".source = home-manager;

	  # the version of this flake used to build the system
	  nix.registry.activeconfig.flake = self;
    environment.etc."nix/path/activeconfig".source = self;

    # the (runtime) current version of this flake
    nix.registry.config.to = { type = "path"; path = "/mnt/persist/flake"; };
    environment.etc."nix/path/config".source = "/mnt/persist/flake";

    # the (runtime) current version of nixos stable
    nix.registry.nixpkgs-stable.to = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-20.09"; };

    # the (runtime) current version of nixos unstable
    nix.registry.nixpkgs-unstable.to = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-unstable"; };
	})
	# import home-manager
	home-manager.nixosModules.home-manager
	# import configuration.nix
	./configuration.nix
        ];
    };

  };
}
