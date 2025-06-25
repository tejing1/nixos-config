{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    mobile-nixos.url = "github:tejing1/mobile-nixos/tejingphone";
    mobile-nixos.flake = false;
  };

  outputs = inputs: (import ./lib inputs).importAllExceptWithArg ./. [ "flake.nix" ] inputs;
}
