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
      base/fpentry.nix
      base/home-manager.nix
      base/hosts.nix
      base/my.nix
      base/nixos.nix
      base/nixpkgs.nix
      base/users.nix
      conf/fpentry.nix
      conf/games/fpentry.nix
      conf/games/starsector/fpentry.nix
      conf/news/fpentry.nix
      conf/nix/fpentry.nix
      conf/nix/registry.nix
      conf/shell/command-not-found.nix
      conf/shell/fpentry.nix
      conf/tejing/fpentry.nix
      conf/users.nix
      dev/dev-shell.nix
      dev/expr-generation.nix
      dev/file-generation.nix
      dev/flake-file.nix
      dev/fpentry.nix
      homeConfigurations/fpentry.nix
      homeConfigurations/tejing/fpentry.nix
      lib/flakeClosureRef.nix
      lib/fpentry.nix
      lib/getImportable.nix
      lib/getImportableExcept.nix
      lib/importSecret.nix
      lib/isRepoLocked.nix
      lib/listImportablePaths.nix
      lib/listImportablePathsExcept.nix
      lib/mkFlake.nix
      lib/mkShellScript.nix
      lib/readSecret.nix
      lib/repoLockedTestResult/fpentry.nix
      nixosConfigurations/fpentry.nix
      nixosConfigurations/tejingdesk/boot.nix
      nixosConfigurations/tejingdesk/bootloader.nix
      nixosConfigurations/tejingdesk/buildvm.nix
      nixosConfigurations/tejingdesk/console.nix
      nixosConfigurations/tejingdesk/cpu.nix
      nixosConfigurations/tejingdesk/customization.nix
      nixosConfigurations/tejingdesk/disks.nix
      nixosConfigurations/tejingdesk/displaymanager.nix
      nixosConfigurations/tejingdesk/emulation.nix
      nixosConfigurations/tejingdesk/fpentry.nix
      nixosConfigurations/tejingdesk/gaming.nix
      nixosConfigurations/tejingdesk/hardware.nix
      nixosConfigurations/tejingdesk/nixos.nix
      nixosConfigurations/tejingdesk/optin-state.nix
      nixosConfigurations/tejingdesk/root.nix
      nixosConfigurations/tejingdesk/security.nix
      nixosConfigurations/tejingdesk/sound.nix
      nixosConfigurations/tejingdesk/ssh.nix
      nixosConfigurations/tejingdesk/time.nix
      nixosConfigurations/tejingdesk/xserver.nix
      nixosConfigurations/tejingdesk/zram.nix
      nixosConfigurations/tejingphone/fpentry.nix
      overlays/fpentry.nix
      overlays/gh-urxvt-fix-termenv/fpentry.nix
      overlays/steam-fix-screensaver/fpentry.nix
      pkgs/fpentry.nix
      pkgs/hred/fpentry.nix
      pkgs/moonlander-firmware/fpentry.nix
      pkgs/vieb.nix
    ];
  };
}
