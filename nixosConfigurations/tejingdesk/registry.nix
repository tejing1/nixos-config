{ config, inputs, inputSpecs, lib, my, ... }:
let
  inherit (builtins) toFile;
  inherit (inputs) nixpkgs home-manager self;
  inherit (lib) mkIf;
  inherit (lib.strings) escapeNixIdentifier;
  inherit (my.lib) mkFlake;
in
{
  # Let 'nixos-version --json' know about the Git revision
  # of this flake.
  system.configurationRevision = mkIf (self ? rev) self.rev;
  nix.nixPath = [ "/etc/nix/path" ];

  # Don't talk to the internet every time I use the registry
  # I don't use it anyway
  nix.extraOptions = "flake-registry = ${toFile "global-registry.json" ''{"flakes":[],"version":2}''}";

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
    "{config,...}: {legacyPackages.${escapeNixIdentifier config.nixpkgs.system}=config.nixosConfigurations.${escapeNixIdentifier config.networking.hostName}.pkgs;}";

  # the (runtime) current version of this flake
  nix.registry.config.to = { type = "path"; path = "/mnt/persist/tejing/flake"; };
  environment.etc."nix/path/config".source = "/mnt/persist/tejing/flake";

  # the (runtime) current version of nixos stable
  nix.registry.nixpkgs-stable.to = inputSpecs.nixpkgs;

  # the (runtime) current version of nixos unstable
  nix.registry.nixpkgs-unstable.to = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-unstable"; };
}
