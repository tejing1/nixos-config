{ pkgs, ... }:
{
  moonlander-firmware = pkgs.callPackage ./firmware.nix {};
}
