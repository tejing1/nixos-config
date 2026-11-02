{ inputs, ... }:

{
  my.flake.inputs.flake-programdb.url = "github:tejing1/flake-programdb";

  perHost.nixos.cfg = { lib, my, ... }: {
    imports = [
      inputs.flake-programdb.nixosModules.flake-programdb
    ];
    options.my.command-not-found.stateDir = lib.mkOption {
      type = lib.types.path;
    };
    config.flake-programdb.enable = true;
    config.flake-programdb.dbDir = my.command-not-found.stateDir;
  };
}
