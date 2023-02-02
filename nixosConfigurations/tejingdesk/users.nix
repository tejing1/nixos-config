{ inputs, ... }:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  # Use /etc/profiles instead of ~/.nix-profile
  # In particular, this allows 'nixos-rebuild build-vm' and home-manager to work together
  home-manager.useUserPackages = true;

  # Use the system's nixpkgs instance
  home-manager.useGlobalPkgs = true;

  home-manager.extraSpecialArgs = { inherit inputs; };

  # Strictly definitional users, passwords, and groups
  users.mutableUsers = false;
}
