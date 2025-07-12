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

    vieb-nix.url = "github:tejing1/vieb-nix";
    vieb-nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-programdb.url = "github:tejing1/flake-programdb";
  };

  outputs = inputs:
    let
      # Pre-evaluate a subset of modules in order to provide values
      # needed for calculating 'imports' elsewhere. Much of the
      # bootstrapping logic lives in ./lib/default.nix
      pre-pre-eval = inputs.nixpkgs.lib.evalModules {
        modules = [ ./lib ];
        specialArgs = {
          inherit inputs;
        };
      };
      pre-eval = inputs.nixpkgs.lib.evalModules {
        modules = [ ./lib ];
        specialArgs = {
          inherit inputs;
          mylib = pre-pre-eval.config.my.lib;
        };
      };
    in
      inputs.flake-parts.lib.mkFlake {
        inherit inputs;
        specialArgs = {
          mylib = pre-eval.config.my.lib;
        };
      } ./.;
}
