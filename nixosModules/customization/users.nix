{ home-manager, inputs, lib, my, nixpkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  imports = [ home-manager.nixosModules.home-manager ];
  options.my.customize.users = mkEnableOption "customization of options applying to all users";
  config = mkIf my.customize.users {
    # Use /etc/profiles instead of ~/.nix-profile
    # In particular, this allows 'nixos-rebuild build-vm' and home-manager to work together
    home-manager.useUserPackages = true;

    # Use the system's nixpkgs instance
    home-manager.useGlobalPkgs = true;

    # Pass specialArgs through to home-manager
    home-manager.extraSpecialArgs = { inherit inputs nixpkgs home-manager; };

    # Import my basic modules for all users
    home-manager.sharedModules = [ inputs.self.homeModules.my ];

    # Strictly definitional users, passwords, and groups
    users.mutableUsers = false;
  };
}
