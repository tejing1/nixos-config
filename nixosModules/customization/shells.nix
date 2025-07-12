{ nixpkgs, inputs, lib, my, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf genAttrs mkOverride;
in

{
  imports = [ inputs.flake-programdb.nixosModules.flake-programdb ];

  options.my.customize.shell = mkEnableOption "shell customization";
  options.my.command-not-found.stateDir = mkOption {
    type = lib.types.path;
  };


  config = mkIf my.customize.shell {
    # undo default shellAliases
    environment.shellAliases = genAttrs [ "l" "ll" "ls" ] (_: mkOverride 999 null);

    flake-programdb.enable = true;
    flake-programdb.dbDir = my.command-not-found.stateDir;
  };
}
