{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    mobile-nixos.url = "github:tejing1/mobile-nixos/tejingphone";
    mobile-nixos.flake = false;

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    vieb-nix.url = "github:tejing1/vieb-nix";
    vieb-nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-programdb.url = "github:tejing1/flake-programdb";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {
    inherit inputs;
    specialArgs = {
      pre-eval = false;
      # Pre-evaluate a subset of modules in order to provide values
      # needed for calculating 'imports' elsewhere. Much of the
      # bootstrapping logic lives in ./lib/default.nix
      mylib = inputs.nixpkgs.lib.pipe {} (inputs.nixpkgs.lib.replicate 2 (mylib: (
        inputs.nixpkgs.lib.evalModules {
          modules = [ ./lib ];
          specialArgs = {
            pre-eval = true;
            inherit inputs mylib;
            inherit (inputs.nixpkgs) lib;
            flake-parts-lib = inputs.flake-parts.lib;
          };
        }
      ).config.my.lib));
    };
  } ./.;
}
