{
  inputs.nixpkgs.url      = "github:NixOS/nixpkgs/nixos-22.05";
  inputs.home-manager.url = "github:nix-community/home-manager/release-22.05";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.flake-utils.url  = "github:numtide/flake-utils";

  outputs = inputs: (import ./lib inputs).importAllExceptWithArg ./. [ "flake.nix" ] inputs;
}
