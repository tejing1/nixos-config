{ config, lib, pkgs, ... }:

{
  # Use /etc/profiles instead of ~/.nix-profile
  # In particular, this allows 'nixos-rebuild build-vm' and home-manager to work together
  home-manager.useUserPackages = true;

  # Use the system's nixpkgs instance
  home-manager.useGlobalPkgs = true;

  # Strictly definitional users, passwords, and groups
  users.mutableUsers = false;

  # Import any subdirectory containing a default.nix file
  imports = builtins.map (n: ./. + "/${n}") (lib.attrNames (lib.filterAttrs (n: v: v == "directory" && builtins.pathExists (./. + "/${n}/default.nix")) (builtins.readDir ./.)));
}
