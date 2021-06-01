{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.home-manager.url = "github:nix-community/home-manager/release-20.09";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs@{ self, nixpkgs, home-manager }: {
    nixosConfigurations = import ./hosts inputs;
  };
}
