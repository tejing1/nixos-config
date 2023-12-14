{ config, home-manager, inputs, inputSpecs, lib, my, nixpkgs, pkgs, ... }:
let
  inherit (builtins) toFile parseFlakeRef;
  inherit (inputs) self;
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.strings) escapeNixIdentifier;
  inherit (my.lib) mkFlake repoLockedTestResult flakeClosureRef;
in
{
  options.my.customize.registry = mkEnableOption "nix flake registry customization";
  config = mkIf my.customize.registry {
    # Let 'nixos-version --json' know about the Git revision
    # of this flake.
    system.configurationRevision = mkIf (self ? rev) self.rev;

    system.extraDependencies = [

      # Save our single IFD derivation so we don't usually have to
      # rebuild it
      repoLockedTestResult

      # Save the whole input closure of this flake, so we have all the
      # nix code necessary to rebuild this system
      (flakeClosureRef self)

    ];

    # Indirect our NIX_PATH through /etc so that it updates without a
    # relog
    nix.nixPath = [ "/etc/nix/path" ];

    # Don't talk to the internet every time I use the registry
    # I don't use it anyway
    nix.settings.flake-registry = toFile "global-registry.json" ''{"flakes":[],"version":2}'';

    # the version of nixpkgs used to build the system
    nix.registry.nixpkgs.flake = nixpkgs;
    environment.etc."nix/path/nixpkgs".source = nixpkgs;

    # the version of home-manager used to build the system
    nix.registry.home-manager.flake = home-manager;
    environment.etc."nix/path/home-manager".source = home-manager;

    # the version of this flake used to build the system
    nix.registry.activeconfig.flake = self;
    environment.etc."nix/path/activeconfig".source = self;

    # build and register a flake to capture this config's pkgs attribute
    nix.registry.pkgs.flake = mkFlake {config = self;}
      "{config,...}: {legacyPackages.${escapeNixIdentifier pkgs.system}=config.nixosConfigurations.${escapeNixIdentifier config.networking.hostName}.pkgs;}";

    # the (runtime) current version of this flake
    nix.registry.config.to = { type = "path"; path = "/mnt/persist/tejing/flake"; };
    environment.etc."nix/path/config".source = "/mnt/persist/tejing/flake";

    # the (runtime) current version of nixos stable
    nix.registry.nixpkgs-stable.to = inputSpecs.nixpkgs;

    # the (runtime) current version of nixos unstable
    nix.registry.nixpkgs-unstable.to = parseFlakeRef "github:NixOS/nixpkgs/nixos-unstable";
  };
}
