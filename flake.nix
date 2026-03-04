# This file is generated. (Yes, really.)
# See file-generation/flake-file.nix for its definition.

{
  inputs = {
    flake-compat = {
      flake = false;
      url = "github:NixOS/flake-compat";
    };
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };
    flake-programdb.url = "github:tejing1/flake-programdb";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-25.11";
    };
    home-manager-unstable = {
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      url = "github:nix-community/home-manager/master";
    };
    mobile-nixos = {
      flake = false;
      url = "github:tejing1/mobile-nixos/tejingphone";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    vieb-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:tejing1/vieb-nix";
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake {
    inherit inputs;
  } {
    imports = builtins.filter builtins.pathExists [
      ./file-generation
      ./fpentry.nix
      ./homeConfigurations
      ./homeModules
      ./lib
      ./my.nix
      ./nixosConfigurations
      ./nixosModules
      ./nixpkgs.nix
      ./overlays
      ./perPkgs.nix
      ./pkgs
      file-generation/flake-file.nix
      file-generation/nix-expr.nix
      lib/flakeClosureRef.nix
      lib/getImportable.nix
      lib/getImportableExcept.nix
      lib/importAll.nix
      lib/importAllExcept.nix
      lib/importAllExceptWithArg.nix
      lib/importAllExceptWithScope.nix
      lib/importAllNamedExceptWithArg.nix
      lib/importAllWithArg.nix
      lib/importSecret.nix
      lib/isRepoLocked.nix
      lib/listImportablePaths.nix
      lib/listImportablePathsExcept.nix
      lib/mkFlake.nix
      lib/mkShellScript.nix
      lib/readSecret.nix
      lib/repoLockedTestResult
      overlays/gh-urxvt-fix-termenv
      overlays/steam-fix-screensaver
      pkgs/hred
      pkgs/moonlander-firmware
      pkgs/starsector
      pkgs/vieb.nix
    ];
    my.flake.modules = [
      ./fpentry.nix
    ];
  };
}
