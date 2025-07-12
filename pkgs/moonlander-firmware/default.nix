{ lib, ... }:

let
  inherit (lib) getExe;
in

{
  my.pkgsFunc = pkgs: {
    moonlander-firmware = pkgs.callPackage ./package.nix {};
  };
  perSystem = { my, pkgs, ... }: {
    apps.moonlander-push = {
      type = "app";
      meta.description = "Build and flash my custom moonlander firmware to the actual hardware.";
      program = pkgs.writeShellScriptBin "moonlander-push" "sudo ${getExe pkgs.wally-cli} ${my.pkgs.moonlander-firmware}";
    };
  };
}
