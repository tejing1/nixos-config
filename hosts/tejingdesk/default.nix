{ self, nixpkgs, home-manager, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
	  # import home-manager
	  home-manager.nixosModules.home-manager

	  ({ pkgs, ... }: {
      # Let 'nixos-version --json' know about the Git revision
      # of this flake.
	    system.configurationRevision = pkgs.lib.mkIf (self ? rev) self.rev;
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
      nix.registry.config.to = { type = "path"; path = "/mnt/persist/tejing/flake"; };
      environment.etc."nix/path/config".source = "/mnt/persist/tejing/flake";

      # the (runtime) current version of nixos stable
      nix.registry.nixpkgs-stable.to = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-20.09"; };

      # the (runtime) current version of nixos unstable
      nix.registry.nixpkgs-unstable.to = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-unstable"; };
	  })
	  # import configuration.nix
	  ./configuration.nix
  ];
}
