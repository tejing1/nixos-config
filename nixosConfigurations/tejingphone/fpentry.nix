{ inputs, ...}:

let
  nixpkgsInput = "nixpkgs-unstable";
  home-managerInput = "home-manager-unstable";

  nixpkgs = inputs.${nixpkgsInput};
  home-manager = inputs.${home-managerInput};
in

{
  my.flake.inputs = {
    mobile-nixos.url = "github:tejing1/mobile-nixos/tejingphone";
    mobile-nixos.flake = false;
  };

  flake.nixosConfigurations.tejingphone = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux"; # mobile-nixos still needs this set. It can't work from nixpkgs.hostPlatorm
    specialArgs = {
      inherit inputs nixpkgs home-manager nixpkgsInput home-managerInput;
    };
    modules = [
      {
        networking.hostName = "tejingphone";
      }
      ./configuration.nix
      ./hardware-configuration.nix
    ];
  };
}
