# This file is generated. (Yes, really.)
# See dev/flake-file.nix for its definition.

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
      ./fpentry.nix
      ./my.nix
      ./nixpkgs.nix
      dev/dev-shell.nix
      dev/expr-generation.nix
      dev/file-generation.nix
      dev/flake-file.nix
      dev/fpentry.nix
      homeConfigurations/fpentry.nix
      homeModules/fpentry.nix
      lib/flakeClosureRef.nix
      lib/fpentry.nix
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
      lib/repoLockedTestResult/fpentry.nix
      nixosConfigurations/fpentry.nix
      nixosConfigurations/tejingdesk/fpentry.nix
      nixosConfigurations/tejingphone/fpentry.nix
      nixosModules/fpentry.nix
      overlays/fpentry.nix
      overlays/gh-urxvt-fix-termenv/fpentry.nix
      overlays/steam-fix-screensaver/fpentry.nix
      pkgs/fpentry.nix
      pkgs/hred/fpentry.nix
      pkgs/moonlander-firmware/fpentry.nix
      pkgs/starsector/fpentry.nix
      pkgs/vieb.nix
    ];
  };
}
